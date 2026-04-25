import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';

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
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _introductionController = TextEditingController();
  final _goalController = TextEditingController();

  String _careerLevel = '신입';
  String _interviewType = '종합 면접';

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _introductionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _startInterview() {
    final companyName = _companyController.text.trim();
    final position = _positionController.text.trim();
    final introduction = _introductionController.text.trim();
    final goal = _goalController.text.trim();

    if (companyName.isEmpty || position.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지원 회사와 지원 직무를 입력해주세요.')));
      return;
    }

    final applicantInfo = ApplicantInfo(
      companyName: companyName,
      position: position,
      careerLevel: _careerLevel,
      interviewType: _interviewType,
      introduction: introduction,
      goal: goal,
    );

    context.goNamed(InterviewScreen.routeName, extra: applicantInfo);
  }

  PageDecoration get _pageDecoration {
    return const PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Colors.black54,
      ),
      pageColor: Color(0xFFF3F4F6),
      imagePadding: EdgeInsets.only(top: 32),
      contentMargin: EdgeInsets.symmetric(horizontal: 20),
      bodyPadding: EdgeInsets.only(top: 12),
      titlePadding: EdgeInsets.only(top: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        globalBackgroundColor: const Color(0xFFF3F4F6),
        pages: [
          PageViewModel(
            title: '어떤 회사에 지원하나요?',
            body: '지원 회사와 직무를 입력하면 AI 면접관이 상황에 맞는 질문을 준비해요.',
            image: const _OnboardingIcon(icon: Icons.business_center_rounded),
            decoration: _pageDecoration,
            footer: _OnboardingCard(
              children: [
                _AppTextField(
                  controller: _companyController,
                  label: '지원 회사',
                  hintText: '예: 네이버, 카카오, 토스',
                ),
                const SizedBox(height: 14),
                _AppTextField(
                  controller: _positionController,
                  label: '지원 직무',
                  hintText: '예: Flutter 개발자, 프론트엔드 개발자',
                ),
              ],
            ),
          ),
          PageViewModel(
            title: '면접 유형을 선택해주세요',
            body: '지원자의 경력과 면접 유형에 맞춰 질문 난이도를 조정해요.',
            image: const _OnboardingIcon(icon: Icons.tune_rounded),
            decoration: _pageDecoration,
            footer: _OnboardingCard(
              children: [
                _AppDropdownField(
                  label: '경력 수준',
                  value: _careerLevel,
                  items: const ['신입', '주니어', '미들', '시니어'],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _careerLevel = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _AppDropdownField(
                  label: '면접 유형',
                  value: _interviewType,
                  items: const ['종합 면접', '인성 면접', '기술 면접', '직무 면접', '임원 면접'],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _interviewType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          PageViewModel(
            title: '면접 목표를 알려주세요',
            body: '자기소개와 목표를 입력하면 더 현실적인 질문을 만들 수 있어요.',
            image: const _OnboardingIcon(icon: Icons.record_voice_over_rounded),
            decoration: _pageDecoration,
            footer: _OnboardingCard(
              children: [
                _AppTextField(
                  controller: _introductionController,
                  label: '간단한 자기소개',
                  hintText: '예: Flutter 앱 개발을 공부하고 있습니다.',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _AppTextField(
                  controller: _goalController,
                  label: '면접 목표',
                  hintText: '예: 프로젝트 설명을 자연스럽게 하고 싶어요.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
        showBackButton: true,
        back: const Text(
          '이전',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C63FF),
          ),
        ),
        next: const Text(
          '다음',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C63FF),
          ),
        ),
        done: const Text(
          '시작하기',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF6C63FF),
          ),
        ),
        onDone: _startInterview,
        dotsDecorator: DotsDecorator(
          size: const Size.square(8),
          activeSize: const Size(22, 8),
          activeColor: const Color(0xFF6C63FF),
          color: const Color(0xFFD1D5DB),
          spacing: const EdgeInsets.symmetric(horizontal: 4),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OnboardingIcon extends StatelessWidget {
  const _OnboardingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 56, color: const Color(0xFF6C63FF)),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: children),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }
}

class _AppDropdownField extends StatelessWidget {
  const _AppDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }
}
