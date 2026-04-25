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
  File? _riveFile;
  RiveWidgetController? _controller;
  BooleanInput? _isTalkingInput;
  bool _isTalking = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    final riveFile = await File.asset(
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

  void _toggleTalking() {
    final input = _isTalkingInput;
    if (input == null) return;

    setState(() {
      _isTalking = !_isTalking;
      input.value = _isTalking;
    });
  }

  @override
  void dispose() {
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
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 360,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: _isLoading || controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : RiveWidget(controller: controller, fit: Fit.contain),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '지혜 면접관',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    applicantInfo == null
                        ? '자기소개를 1분 이내로 해주세요.'
                        : '${applicantInfo.companyName} ${applicantInfo.position} 면접을 시작할게요.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (applicantInfo != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${applicantInfo.careerLevel} · ${applicantInfo.interviewType}',
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isTalkingInput == null ? null : _toggleTalking,
                  child: Text(_isTalking ? '말하기 중지' : '말하기 시작'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
