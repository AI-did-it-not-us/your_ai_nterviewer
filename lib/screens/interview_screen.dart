import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

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
  final ScrollController _scrollController = ScrollController();

  File? _riveFile;
  RiveWidgetController? _controller;
  BooleanInput? _isTalkingInput;

  bool _isLoading = true;
  bool _isWaitingInterviewer = false;
  bool _isCompleted = false;

  int _turnIndex = 0;

  final List<_InterviewMessage> _messages = [];

  final List<String> _sampleAnswers = const [
    '안녕하세요. 저는 사용자 경험을 중요하게 생각하는 개발자입니다.\nFlutter를 활용해 앱 화면과 상태 관리를 구성한 경험이 있습니다.\n입사 후에는 빠르게 적응해서 서비스 품질을 높이는 데 기여하고 싶습니다.',
    '프로젝트에서는 PDF를 기반으로 퀴즈를 생성하고 결과를 분석하는 기능을 만들었습니다.\n특히 사용자의 풀이 기록을 저장하고 점수와 평균 시간을 보여주는 구조를 고민했습니다.\n데이터 모델을 분리해서 나중에 확장하기 쉽게 만드는 데 집중했습니다.',
    '어려웠던 점은 여러 화면에서 상태가 바뀔 때 UI를 안정적으로 동기화하는 부분이었습니다.\n그래서 Provider 구조를 정리하고 필요한 화면만 다시 빌드되도록 개선했습니다.\n그 과정에서 코드 구조와 유지보수성의 중요성을 배웠습니다.',
  ];

  final List<String> _sampleReplies = const [
    '좋습니다. Flutter 프로젝트에서 상태 관리를 Riverpod으로 선택한 이유를 설명해볼 수 있을까요?',
    '좋은 경험이네요. 모델을 분리할 때 어떤 기준으로 테이블이나 클래스를 나누었는지 조금 더 구체적으로 말해볼까요?',
    '좋습니다. 마지막으로 본인이 이 회사에 들어와서 가장 빠르게 기여할 수 있는 부분은 무엇이라고 생각하나요?',
  ];

  @override
  void initState() {
    super.initState();
    _loadRive();
    _initMessages();
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

  Future<void> _handleMicTap() async {
    if (_isWaitingInterviewer || _isCompleted) return;
    if (_turnIndex >= _sampleAnswers.length) return;

    setState(() {
      _messages.add(
        _InterviewMessage(
          isInterviewer: false,
          text: _sampleAnswers[_turnIndex],
        ),
      );
      _isWaitingInterviewer = true;
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    _isTalkingInput?.value = true;

    setState(() {
      _messages.add(
        _InterviewMessage(
          isInterviewer: true,
          text: _sampleReplies[_turnIndex],
        ),
      );
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    _isTalkingInput?.value = false;

    setState(() {
      _turnIndex += 1;
      _isWaitingInterviewer = false;
      _isCompleted = _turnIndex >= _sampleAnswers.length;
    });
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
    _scrollController.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.white70,
        title: const Text('AI 면접 연습'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  children: [
                    Container(
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
                    Column(
                      children: [
                        for (final message in _messages) ...[
                          _MessageBubble(message: message),
                          const SizedBox(height: 12),
                        ],
                        if (_isWaitingInterviewer) ...[
                          const SizedBox(height: 4),
                          const _InterviewerTypingIndicator(),
                        ],
                      ],
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
                    onTap: _isWaitingInterviewer || _isCompleted
                        ? null
                        : _handleMicTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCompleted
                            ? const Color(0xFFF0EFFF)
                            : _isWaitingInterviewer
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF6C63FF),
                        border: Border.all(
                          color: _isCompleted
                              ? const Color(0xFF6C63FF)
                              : _isWaitingInterviewer
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6C63FF),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isCompleted
                            ? Icons.check_rounded
                            : _isWaitingInterviewer
                            ? Icons.hourglass_top_rounded
                            : Icons.mic_rounded,
                        size: 34,
                        color: _isCompleted
                            ? const Color(0xFF6C63FF)
                            : _isWaitingInterviewer
                            ? Colors.black45
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isCompleted
                        ? '테스트 대화 완료'
                        : _isWaitingInterviewer
                        ? '면접관이 답변 중입니다'
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
