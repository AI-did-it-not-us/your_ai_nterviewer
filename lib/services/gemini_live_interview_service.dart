import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/applicant_info.dart';
import '../models/gemini_live_interview_state.dart';
import 'interview_prompt_builder.dart';

class GeminiLiveInterviewService extends ChangeNotifier {
  GeminiLiveInterviewState _state = const GeminiLiveInterviewState();
  GeminiLiveInterviewState get state => _state;

  bool get hasApiKey => _apiKey.isNotEmpty;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _host = 'generativelanguage.googleapis.com';
  static const String _path =
      '/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
  static const String _model =
      'models/gemini-2.5-flash-native-audio-preview-12-2025';
  static const int _outputSampleRate = 24000;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Completer<void>? _connectCompleter;
  Completer<void>? _setupCompleter;

  final Queue<ByteData> _audioQueue = Queue<ByteData>();

  bool _socketReady = false;
  bool _setupComplete = false;
  bool _playerReady = false;
  bool _disposed = false;
  bool _generationComplete = false;
  bool _isFeedingAudio = false;
  bool _nativePlaybackDrained = true;
  int _playbackToken = 0;
  DateTime _estimatedPlaybackDrainAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> sendUserText({
    required String text,
    required ApplicantInfo? applicantInfo,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _state.isBusy) return;

    if (!hasApiKey) {
      _fail('GEMINI_API_KEY가 설정되지 않았습니다. --dart-define으로 API 키를 전달해주세요.');
      return;
    }

    try {
      await _connect(applicantInfo);
    } catch (_) {
      return;
    }

    _startResponse();
    _sendJson({
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': trimmedText},
            ],
          },
        ],
        'turnComplete': true,
      },
    });
  }

  Future<void> _connect(ApplicantInfo? applicantInfo) async {
    if (_socketReady && _setupComplete) return;
    final pendingConnect = _connectCompleter;
    if (pendingConnect != null) return pendingConnect.future;

    final connectCompleter = Completer<void>();
    _connectCompleter = connectCompleter;
    _emit(
      _state.copyWith(
        status: GeminiLiveInterviewStatus.connecting,
        errorMessage: null,
      ),
    );

    try {
      await _preparePlayer();

      final uri = Uri(
        scheme: 'wss',
        host: _host,
        path: _path,
        queryParameters: {'key': _apiKey},
      );

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 15));
      _socketReady = true;

      _channelSubscription = channel.stream.listen(
        _handleSocketMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
      );

      _setupCompleter = Completer<void>();
      _sendJson(_setupPayload(applicantInfo));
      await _setupCompleter!.future.timeout(const Duration(seconds: 15));

      _emit(_state.copyWith(status: GeminiLiveInterviewStatus.ready));
      connectCompleter.complete();
    } catch (error) {
      _fail('Gemini 연결에 실패했습니다: $error');
      await _cleanup();
      if (!connectCompleter.isCompleted) {
        connectCompleter.completeError(error);
      }
    } finally {
      _connectCompleter = null;
    }
  }

  Future<void> _preparePlayer() async {
    if (_playerReady) return;

    await FlutterPcmSound.setup(
      sampleRate: _outputSampleRate,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playback,
    );
    await FlutterPcmSound.setFeedThreshold(_outputSampleRate ~/ 10);
    FlutterPcmSound.setFeedCallback((remainingFrames) {
      if (remainingFrames == 0) {
        _nativePlaybackDrained = true;
        _completeResponseIfPlaybackDone();
      }
    });
    _playerReady = true;
  }

  void _startResponse() {
    _audioQueue.clear();
    _generationComplete = false;
    _nativePlaybackDrained = true;
    _estimatedPlaybackDrainAt = DateTime.now();
    _playbackToken += 1;
    _emit(
      _state.copyWith(
        status: GeminiLiveInterviewStatus.waitingResponse,
        isAiSpeaking: false,
        currentResponseText: '',
        errorMessage: null,
      ),
    );
  }

  void _handleSocketMessage(dynamic message) {
    try {
      final decoded = switch (message) {
        String value => jsonDecode(value),
        List<int> value => jsonDecode(utf8.decode(value)),
        _ => null,
      };

      if (decoded is! Map<String, dynamic>) return;

      final error = _asMap(decoded['error']);
      if (error != null) {
        _fail(error['message']?.toString() ?? 'Gemini 오류가 발생했습니다.');
        return;
      }

      if (decoded.containsKey('setupComplete')) {
        _setupComplete = true;
        final setupCompleter = _setupCompleter;
        if (setupCompleter != null && !setupCompleter.isCompleted) {
          setupCompleter.complete();
        }
      }

      final serverContent = _asMap(decoded['serverContent']);
      if (serverContent != null) {
        _handleServerContent(serverContent);
      }

      if (decoded.containsKey('goAway')) {
        _emit(
          _state.copyWith(
            errorMessage: 'Gemini 세션 종료가 예정되었습니다. 다음 답변에서 다시 연결됩니다.',
          ),
        );
      }
    } catch (error) {
      _emit(_state.copyWith(errorMessage: 'Gemini 응답 처리 실패: $error'));
    }
  }

  void _handleServerContent(Map<String, dynamic> serverContent) {
    if (serverContent['interrupted'] == true) {
      unawaited(_resetPlayback());
    }

    final outputTranscription = _asMap(serverContent['outputTranscription']);
    final outputText = outputTranscription?['text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      _appendResponseText(outputText);
    }

    final modelTurn = _asMap(serverContent['modelTurn']);
    final parts = modelTurn?['parts'];
    if (parts is List) {
      for (final part in parts) {
        final partMap = _asMap(part);
        final text = partMap?['text'];
        if (text is String && text.trim().isNotEmpty) {
          _appendResponseText(text);
        }

        final inlineData = _asMap(partMap?['inlineData']);
        final data = inlineData?['data'];
        if (data is String && data.isNotEmpty) {
          _enqueueAudio(data);
        }
      }
    }

    if (serverContent['turnComplete'] == true ||
        serverContent['generationComplete'] == true) {
      _generationComplete = true;
      _completeResponseIfPlaybackDone();
      _scheduleEstimatedCompletion();
    }
  }

  void _appendResponseText(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final currentText = _state.currentResponseText;
    final nextText = currentText.isEmpty
        ? trimmedText
        : '$currentText $trimmedText';
    _emit(_state.copyWith(currentResponseText: nextText));
  }

  void _enqueueAudio(String base64Pcm) {
    final bytes = base64Decode(base64Pcm);
    if (bytes.isEmpty) return;

    final evenLength = bytes.length.isEven ? bytes.length : bytes.length - 1;
    final byteData = bytes.buffer.asByteData(bytes.offsetInBytes, evenLength);
    _audioQueue.add(byteData);

    final now = DateTime.now();
    final chunkDuration = Duration(
      milliseconds: ((evenLength / 2) / _outputSampleRate * 1000).ceil(),
    );
    final estimateBase = _estimatedPlaybackDrainAt.isAfter(now)
        ? _estimatedPlaybackDrainAt
        : now;
    _estimatedPlaybackDrainAt = estimateBase.add(chunkDuration);

    _nativePlaybackDrained = false;
    _emit(
      _state.copyWith(
        status: GeminiLiveInterviewStatus.speaking,
        isAiSpeaking: true,
      ),
    );
    unawaited(_pumpAudioQueue());
  }

  Future<void> _pumpAudioQueue() async {
    if (_isFeedingAudio || !_playerReady) return;

    _isFeedingAudio = true;
    try {
      while (_audioQueue.isNotEmpty && _playerReady) {
        await FlutterPcmSound.feed(
          PcmArrayInt16(bytes: _audioQueue.removeFirst()),
        );
        FlutterPcmSound.start();
      }
    } finally {
      _isFeedingAudio = false;
      _completeResponseIfPlaybackDone();
    }
  }

  void _scheduleEstimatedCompletion() {
    final token = _playbackToken;
    final rawDelay = _estimatedPlaybackDrainAt.difference(DateTime.now());
    final positiveDelay = rawDelay.isNegative ? Duration.zero : rawDelay;
    final delay = positiveDelay < const Duration(milliseconds: 250)
        ? const Duration(milliseconds: 250)
        : positiveDelay > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : positiveDelay;

    Future.delayed(delay + const Duration(milliseconds: 350), () {
      if (_disposed || token != _playbackToken) return;
      _nativePlaybackDrained = true;
      _completeResponseIfPlaybackDone();
    });
  }

  void _completeResponseIfPlaybackDone() {
    if (!_generationComplete || _audioQueue.isNotEmpty || _isFeedingAudio) {
      return;
    }

    if (!_nativePlaybackDrained && _state.isAiSpeaking) return;

    _emit(
      _state.copyWith(
        status: GeminiLiveInterviewStatus.ready,
        isAiSpeaking: false,
      ),
    );
  }

  Future<void> _resetPlayback() async {
    _audioQueue.clear();
    _playbackToken += 1;
    if (_playerReady) {
      await FlutterPcmSound.release();
      _playerReady = false;
    }
    _nativePlaybackDrained = true;
    _isFeedingAudio = false;
    _emit(_state.copyWith(isAiSpeaking: false));
    await _preparePlayer();
  }

  Map<String, dynamic> _setupPayload(ApplicantInfo? applicantInfo) {
    return {
      'setup': {
        'model': _model,
        'generationConfig': {
          'temperature': 0.8,
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {'voiceName': 'Kore'},
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': InterviewPromptBuilder.build(applicantInfo)},
          ],
        },
        'outputAudioTranscription': {},
      },
    };
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (!_socketReady && !payload.containsKey('setup')) return;

    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (error) {
      _fail('Gemini로 메시지를 보내지 못했습니다: $error');
    }
  }

  void _handleSocketError(Object error, [StackTrace? stackTrace]) {
    _fail('Gemini WebSocket 오류: $error');
  }

  void _handleSocketDone() {
    _socketReady = false;
    _setupComplete = false;

    if (_state.status == GeminiLiveInterviewStatus.error) return;

    _emit(
      _state.copyWith(
        status: GeminiLiveInterviewStatus.idle,
        isAiSpeaking: false,
      ),
    );
  }

  Future<void> _cleanup() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
    _socketReady = false;
    _setupComplete = false;
    _connectCompleter = null;
    _setupCompleter = null;
    _audioQueue.clear();

    if (_playerReady) {
      await FlutterPcmSound.release();
      _playerReady = false;
    }
  }

  Map<String, dynamic>? _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }

  void _fail(String message) {
    _emit(
      _state.copyWith(
        status: GeminiLiveInterviewStatus.error,
        isAiSpeaking: false,
        errorMessage: message,
      ),
    );
  }

  void _emit(GeminiLiveInterviewState nextState) {
    if (_disposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cleanup());
    super.dispose();
  }
}
