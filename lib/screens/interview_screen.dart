import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/applicant_info.dart';
import '../services/gemini_live_interview_service.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key, required this.applicantInfo});

  static const routeName = 'interview';
  static const routePath = '/interview';

  final ApplicantInfo? applicantInfo;

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final GeminiLiveInterviewService _geminiService =
      GeminiLiveInterviewService();

  File? _riveFile;
  RiveWidgetController? _controller;
  BooleanInput? _isTalkingInput;

  bool _isLoading = true;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isFinalizingSpeech = false;
  bool _isWaitingInterviewer = false;

  String _currentAnswerText = '';
  String? _speechErrorMessage;
  String? _geminiErrorMessage;
  int? _activeInterviewerMessageIndex;

  final List<_InterviewMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _geminiService.addListener(_handleGeminiChanged);
    _loadRive();
    _initMessages();
    _initSpeech();
  }

  void _initMessages() {
    _messages.add(
      _InterviewMessage(
        isInterviewer: true,
        text: '$_interviewTypeText을 시작하겠습니다. 먼저 자기소개를 해주세요.',
      ),
    );
  }

  String get _interviewTypeText {
    final applicantInfo = widget.applicantInfo;

    if (applicantInfo == null) return '면접';
    if (applicantInfo.position.isNotEmpty) return applicantInfo.position;
    if (applicantInfo.companyName.isNotEmpty) return applicantInfo.companyName;

    return '면접';
  }

  String get _appBarTitle {
    return widget.applicantInfo?.interviewerName ?? '지혜';
  }

  String get _appBarSubtitle {
    final applicantInfo = widget.applicantInfo;

    if (applicantInfo == null) return 'AI 면접 연습';

    return '$_interviewTypeText · ${applicantInfo.interviewerStyle} · ${applicantInfo.interviewGoal}';
  }

  Future<void> _loadRive() async {
    final riveFile = await File.asset(
      widget.applicantInfo?.interviewerRivePath ??
          'assets/rives/jihye_anchor.riv',
      riveFactory: Factory.rive,
    );

    if (riveFile == null) return;

    final controller = RiveWidgetController(
      riveFile,
      stateMachineSelector: StateMachineSelector.byName('State Machine'),
    );

    // ignore: deprecated_member_use
    final isTalkingInput = controller.stateMachine.boolean('isTalking');
    isTalkingInput?.value = false;

    if (!mounted) return;

    setState(() {
      _riveFile = riveFile;
      _controller = controller;
      _isTalkingInput = isTalkingInput;
      _isLoading = false;
    });
  }

  Future<void> _initSpeech() async {
    final enabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          if (_isListening) {
            unawaited(_finishListeningAndSubmit());
          }
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _isListening = false;
          _isFinalizingSpeech = false;
          _speechErrorMessage = error.errorMsg;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _speechEnabled = enabled;
    });
  }

  Future<void> _handleMicTap() async {
    if (_isWaitingInterviewer) return;

    if (_isListening) {
      await _finishListeningAndSubmit();
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_geminiService.hasApiKey) {
      setState(() {
        _geminiErrorMessage =
            'GEMINI_API_KEY가 설정되지 않았습니다. --dart-define으로 API 키를 전달해주세요.';
      });
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (!_speechToText.isAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성 인식을 사용할 수 없습니다.')));
      return;
    }

    setState(() {
      _isListening = true;
      _isFinalizingSpeech = false;
      _currentAnswerText = '';
      _speechErrorMessage = null;
      _geminiErrorMessage = null;
    });

    await _speechToText.listen(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _currentAnswerText = result.recognizedWords;
        });

        if (result.finalResult) {
          unawaited(_finishListeningAndSubmit());
        }
      },
    );
  }

  Future<void> _finishListeningAndSubmit() async {
    if (_isFinalizingSpeech) return;

    _isFinalizingSpeech = true;
    final answerText = _currentAnswerText.trim();

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    if (!mounted) {
      _isFinalizingSpeech = false;
      return;
    }

    setState(() {
      _isListening = false;
    });

    if (answerText.isEmpty) {
      setState(() {
        _isFinalizingSpeech = false;
      });
      return;
    }

    await _submitAnswer(answerText);

    if (!mounted) return;
    setState(() {
      _isFinalizingSpeech = false;
    });
  }

  Future<void> _submitAnswer(String answerText) async {
    setState(() {
      _messages.add(_InterviewMessage(isInterviewer: false, text: answerText));
      _currentAnswerText = '';
      _isWaitingInterviewer = true;
      _activeInterviewerMessageIndex = null;
      _geminiErrorMessage = null;
    });

    _scrollToBottom();

    await _geminiService.sendUserText(
      text: answerText,
      applicantInfo: widget.applicantInfo,
    );
  }

  void _handleGeminiChanged() {
    final liveState = _geminiService.state;
    _isTalkingInput?.value = liveState.isAiSpeaking;

    if (!mounted) return;

    setState(() {
      _isWaitingInterviewer = liveState.isBusy;
      _geminiErrorMessage = liveState.errorMessage;

      final responseText = liveState.currentResponseText.trim();
      if (responseText.isNotEmpty) {
        final activeIndex = _activeInterviewerMessageIndex;
        if (activeIndex == null ||
            activeIndex < 0 ||
            activeIndex >= _messages.length ||
            !_messages[activeIndex].isInterviewer) {
          _messages.add(
            _InterviewMessage(isInterviewer: true, text: responseText),
          );
          _activeInterviewerMessageIndex = _messages.length - 1;
        } else {
          _messages[activeIndex] = _messages[activeIndex].copyWith(
            text: responseText,
          );
        }
      }

      if (!liveState.isBusy) {
        _activeInterviewerMessageIndex = null;
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _geminiService.removeListener(_handleGeminiChanged);
    _geminiService.dispose();
    _scrollController.dispose();
    _isTalkingInput?.dispose();
    _controller?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canUseMic = !_isWaitingInterviewer;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _appBarTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _appBarSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                width: double.infinity,
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _isLoading || controller == null
                    ? const Center(child: CircularProgressIndicator())
                    : RiveWidget(controller: controller, fit: Fit.contain),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    for (final message in _messages) ...[
                      _MessageBubble(message: message),
                      const SizedBox(height: 12),
                    ],
                    if (_isListening) ...[
                      _ListeningDraftBubble(text: _currentAnswerText),
                      const SizedBox(height: 12),
                    ],
                    if (_isWaitingInterviewer) ...[
                      const SizedBox(height: 4),
                      const _InterviewerTypingIndicator(),
                    ],
                    if (_speechErrorMessage != null ||
                        _geminiErrorMessage != null) ...[
                      const SizedBox(height: 12),
                      _ErrorNotice(
                        message: _speechErrorMessage ?? _geminiErrorMessage!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: canUseMic ? _handleMicTap : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isWaitingInterviewer
                            ? const Color(0xFFE5E7EB)
                            : _isListening
                            ? const Color(0xFFFFE5E5)
                            : const Color(0xFF6C63FF),
                        border: Border.all(
                          color: _isWaitingInterviewer
                              ? const Color(0xFFD1D5DB)
                              : _isListening
                              ? const Color(0xFFFF4D4D)
                              : const Color(0xFF6C63FF),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isWaitingInterviewer
                            ? Icons.hourglass_top_rounded
                            : _isListening
                            ? Icons.send_rounded
                            : Icons.mic_rounded,
                        size: 34,
                        color: _isWaitingInterviewer
                            ? Colors.black45
                            : _isListening
                            ? const Color(0xFFFF4D4D)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isWaitingInterviewer
                        ? '면접관이 답변 중입니다'
                        : _isListening
                        ? '탭해서 답변 전송'
                        : '탭해서 답변하기',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewMessage {
  const _InterviewMessage({required this.isInterviewer, required this.text});

  final bool isInterviewer;
  final String text;

  _InterviewMessage copyWith({String? text}) {
    return _InterviewMessage(
      isInterviewer: isInterviewer,
      text: text ?? this.text,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _InterviewMessage message;

  @override
  Widget build(BuildContext context) {
    final isInterviewer = message.isInterviewer;

    return Row(
      mainAxisAlignment: isInterviewer
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isInterviewer) ...[
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFF0EFFF),
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isInterviewer
                  ? const Color(0xFFF9FAFB)
                  : const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(18),
              border: isInterviewer
                  ? Border.all(color: const Color(0xFFE5E7EB))
                  : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isInterviewer ? Colors.black : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (!isInterviewer) ...[
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF6C63FF),
            child: Icon(Icons.mic_rounded, size: 18, color: Colors.white),
          ),
        ],
      ],
    );
  }
}

class _ListeningDraftBubble extends StatelessWidget {
  const _ListeningDraftBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final displayText = text.trim().isEmpty ? '음성을 인식하고 있습니다...' : text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCCC7FF)),
            ),
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF3D348B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFF6C63FF),
          child: Icon(Icons.graphic_eq_rounded, size: 18, color: Colors.white),
        ),
      ],
    );
  }
}

class _InterviewerTypingIndicator extends StatelessWidget {
  const _InterviewerTypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFF0EFFF),
          child: Icon(Icons.person_rounded, size: 18, color: Color(0xFF6C63FF)),
        ),
        SizedBox(width: 8),
        Text(
          '면접관이 답변을 준비 중입니다...',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFFB91C1C),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
