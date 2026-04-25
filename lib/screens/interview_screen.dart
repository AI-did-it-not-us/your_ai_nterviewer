import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/applicant_info.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key, required this.applicantInfo});

  static const routeName = 'interview';
  static const routePath = '/interview';

  final ApplicantInfo? applicantInfo;

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  File? _riveFile;
  RiveWidgetController? _controller;
  BooleanInput? _isTalkingInput;

  bool _isLoading = true;
  bool _speechEnabled = false;
  bool _isListening = false;

  String _answerText = '';
  String? _speechErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadRive();
    _initSpeech();
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
          if (!mounted) return;

          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _isListening = false;
          _speechErrorMessage = error.errorMsg;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _speechEnabled = enabled;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
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
      _speechErrorMessage = null;
    });

    await _speechToText.listen(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 5),
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _answerText = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _isTalkingInput?.dispose();
    _controller?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicantInfo = widget.applicantInfo;
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 면접 연습'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: _isLoading || controller == null
                          ? const Center(child: CircularProgressIndicator())
                          : RiveWidget(
                              controller: controller,
                              fit: Fit.contain,
                            ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicantInfo?.interviewerName ?? '지혜',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            applicantInfo == null
                                ? '자기소개를 1분 이내로 해주세요.'
                                : '${applicantInfo.companyName} 면접을 시작할게요.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (applicantInfo != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              '${applicantInfo.interviewerStyle} · ${applicantInfo.interviewGoal}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isListening
                                    ? Icons.graphic_eq_rounded
                                    : Icons.notes_rounded,
                                color: const Color(0xFF6C63FF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isListening ? '답변 인식 중' : '내 답변',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _answerText.isEmpty
                                ? _isListening
                                      ? '말씀하시면 여기에 텍스트로 표시됩니다.'
                                      : '마이크 버튼을 누르고 답변을 시작해주세요.'
                                : _answerText,
                            style: TextStyle(
                              fontSize: 16,
                              color: _answerText.isEmpty
                                  ? Colors.black45
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_speechErrorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _speechErrorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFFFE5E5)
                            : const Color(0xFF6C63FF),
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFFFF4D4D)
                              : const Color(0xFF6C63FF),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 34,
                        color: _isListening
                            ? const Color(0xFFFF4D4D)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isListening ? '탭해서 답변 종료' : '탭해서 답변 시작',
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
