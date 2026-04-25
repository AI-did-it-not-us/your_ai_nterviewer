import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';

import '../models/applicant_info.dart';
import 'interview_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = 'onboarding';
  static const routePath = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentIndex = 0;

  final _interviewers = const [
    _InterviewerOption(
      name: '지혜',
      type: '차분형',
      description: '차분하고 안정적인 분위기로 면접을 진행합니다.',
      rivePath: 'assets/rives/jihye_anchor.riv',
    ),
    _InterviewerOption(
      name: '서연',
      type: '친근형',
      description: '밝고 친근한 분위기로 답변을 이끌어줍니다.',
      rivePath: 'assets/rives/seoyeon_anchor.riv',
    ),
  ];

  final _styles = const [
    _ChoiceOption(
      title: '친절형',
      description: '편안하게 답변할 수 있도록 부드럽게 질문합니다.',
      icon: Icons.sentiment_satisfied_alt_rounded,
    ),
    _ChoiceOption(
      title: '차분형',
      description: '침착하고 안정적인 분위기로 면접을 진행합니다.',
      icon: Icons.spa_rounded,
    ),
    _ChoiceOption(
      title: '압박형',
      description: '꼬리질문과 날카로운 질문으로 실전감을 높입니다.',
      icon: Icons.bolt_rounded,
    ),
    _ChoiceOption(
      title: '실무형',
      description: '경험, 문제해결력, 협업 역량을 중심으로 질문합니다.',
      icon: Icons.work_rounded,
    ),
  ];

  final _types = const [
    _ChoiceOption(
      title: '인성 면접',
      description: '성격, 가치관, 협업 태도를 중심으로 연습합니다.',
      icon: Icons.groups_rounded,
    ),
    _ChoiceOption(
      title: '직무 면접',
      description: '지원 직무와 관련된 경험을 중심으로 연습합니다.',
      icon: Icons.badge_rounded,
    ),
    _ChoiceOption(
      title: '기술 면접',
      description: '기술 이해도와 문제해결 과정을 중심으로 연습합니다.',
      icon: Icons.code_rounded,
    ),
    _ChoiceOption(
      title: '임원 면접',
      description: '태도, 성장 가능성, 조직 적합성을 중심으로 연습합니다.',
      icon: Icons.apartment_rounded,
    ),
  ];

  final _goals = const [
    _ChoiceOption(
      title: '자기소개',
      description: '첫인상과 말의 흐름을 자연스럽게 다듬습니다.',
      icon: Icons.face_rounded,
    ),
    _ChoiceOption(
      title: '지원동기',
      description: '왜 지원했는지 설득력 있게 말하는 연습을 합니다.',
      icon: Icons.flag_rounded,
    ),
    _ChoiceOption(
      title: '프로젝트 설명',
      description: '경험과 성과를 구조적으로 설명하는 연습을 합니다.',
      icon: Icons.layers_rounded,
    ),
    _ChoiceOption(
      title: '실전 연습',
      description: '실제 면접처럼 질문과 답변을 이어갑니다.',
      icon: Icons.mic_rounded,
    ),
  ];

  late _InterviewerOption _selectedInterviewer = _interviewers.first;
  late _ChoiceOption _selectedStyle = _styles.first;
  late _ChoiceOption _selectedType = _types.first;
  late _ChoiceOption _selectedGoal = _goals.first;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex == 4) {
      _startInterview();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goBack() {
    if (_currentIndex == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _startInterview() {
    final applicantInfo = ApplicantInfo(
      companyName: _selectedType.title,
      position: _selectedType.title,
      interviewerName: _selectedInterviewer.name,
      interviewerRivePath: _selectedInterviewer.rivePath,
      interviewerStyle: _selectedStyle.title,
      interviewGoal: _selectedGoal.title,
    );

    context.goNamed(
      InterviewScreen.routeName,
      extra: applicantInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _TopProgress(
              currentIndex: _currentIndex,
              totalCount: 5,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _OnboardingPage(
                    step: '1단계',
                    title: '누구와 면접을 볼까요?',
                    description: '면접을 진행할 AI 면접관을 선택해주세요.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final interviewer in _interviewers) ...[
                          _InterviewerCard(
                            option: interviewer,
                            selected: _selectedInterviewer == interviewer,
                            onTap: () {
                              setState(() {
                                _selectedInterviewer = interviewer;
                              });
                            },
                          ),
                          if (interviewer != _interviewers.last) const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    step: '2단계',
                    title: '면접관 스타일을 선택하세요',
                    description: '원하는 분위기에 맞춰 질문 방식이 달라집니다.',
                    child: _ChoiceGrid(
                      options: _styles,
                      selectedOption: _selectedStyle,
                      onSelected: (option) {
                        setState(() {
                          _selectedStyle = option;
                        });
                      },
                    ),
                  ),
                  _OnboardingPage(
                    step: '3단계',
                    title: '어떤 면접을 준비하나요?',
                    description: '준비하려는 면접 유형을 선택해주세요.',
                    child: _ChoiceGrid(
                      options: _types,
                      selectedOption: _selectedType,
                      onSelected: (option) {
                        setState(() {
                          _selectedType = option;
                        });
                      },
                    ),
                  ),
                  _OnboardingPage(
                    step: '4단계',
                    title: '오늘의 목표는 무엇인가요?',
                    description: '가장 연습하고 싶은 목표를 선택해주세요.',
                    child: _ChoiceGrid(
                      options: _goals,
                      selectedOption: _selectedGoal,
                      onSelected: (option) {
                        setState(() {
                          _selectedGoal = option;
                        });
                      },
                    ),
                  ),
                  _OnboardingPage(
                    step: '5단계',
                    title: '설정을 확인해주세요',
                    description: '선택한 설정으로 면접 연습을 시작합니다.',
                    child: Column(
                      children: [
                        _SummaryCard(
                          title: '면접관',
                          value:
                          '${_selectedInterviewer.name} · ${_selectedInterviewer.type}',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 12),
                        _SummaryCard(
                          title: '면접관 스타일',
                          value: _selectedStyle.title,
                          icon: Icons.psychology_alt_rounded,
                        ),
                        const SizedBox(height: 12),
                        _SummaryCard(
                          title: '면접 유형',
                          value: _selectedType.title,
                          icon: Icons.business_center_rounded,
                        ),
                        const SizedBox(height: 12),
                        _SummaryCard(
                          title: '면접 목표',
                          value: _selectedGoal.title,
                          icon: Icons.flag_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  if (_currentIndex != 0)
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _goBack,
                          child: const Text('이전'),
                        ),
                      ),
                    ),
                  if (_currentIndex != 0) const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _goNext,
                        child: Text(isLastPage ? '면접 시작' : '다음'),
                      ),
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

class _TopProgress extends StatelessWidget {
  const _TopProgress({
    required this.currentIndex,
    required this.totalCount,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          for (int index = 0; index < totalCount; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                decoration: BoxDecoration(
                  color: index <= currentIndex
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (index != totalCount - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.step,
    required this.title,
    required this.description,
    required this.child,
  });

  final String step;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _InterviewerOption {
  const _InterviewerOption({
    required this.name,
    required this.type,
    required this.description,
    required this.rivePath,
  });

  final String name;
  final String type;
  final String description;
  final String rivePath;
}

class _ChoiceOption {
  const _ChoiceOption({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _InterviewerCard extends StatelessWidget {
  const _InterviewerCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _InterviewerOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: selected ? const Color(0xFF6C63FF) : Colors.black26,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: Center(
              child: _InterviewerRivePreview(
                rivePath: option.rivePath,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            option.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.type,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewerRivePreview extends StatefulWidget {
  const _InterviewerRivePreview({
    required this.rivePath,
  });

  final String rivePath;

  @override
  State<_InterviewerRivePreview> createState() =>
      _InterviewerRivePreviewState();
}

class _InterviewerRivePreviewState extends State<_InterviewerRivePreview> {
  File? _riveFile;
  RiveWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    final riveFile = await File.asset(
      widget.rivePath,
      riveFactory: Factory.rive,
    );

    if (riveFile == null) return;

    final controller = RiveWidgetController(
      riveFile,
      stateMachineSelector: StateMachineSelector.byName('State Machine'),
    );

    if (!mounted) return;

    setState(() {
      _riveFile = riveFile;
      _controller = controller;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RiveWidget(
      controller: controller,
      fit: Fit.contain,
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  final List<_ChoiceOption> options;
  final _ChoiceOption selectedOption;
  final ValueChanged<_ChoiceOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: options.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final option = options[index];

        return _ChoiceCard(
          option: option,
          selected: selectedOption == option,
          onTap: () {
            onSelected(option);
          },
        );
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                option.icon,
                size: 30,
                color: selected ? const Color(0xFF6C63FF) : Colors.black54,
              ),
              const Spacer(),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? const Color(0xFF6C63FF) : Colors.black26,
              ),
            ],
          ),
          const Spacer(),
          Text(
            option.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF6C63FF) : const Color(0xFFE5E7EB),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}