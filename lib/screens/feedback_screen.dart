import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/interview_feedback.dart';
import '../services/gemini_feedback_service.dart';
import 'onboarding_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.payload,
    this.feedbackService,
  });

  static const routeName = 'feedback';
  static const routePath = '/feedback';

  final InterviewFeedbackPayload payload;
  final InterviewFeedbackGenerator? feedbackService;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final InterviewFeedbackGenerator _feedbackService;
  late final bool _ownsFeedbackService;

  bool _isLoading = true;
  InterviewFeedbackResult? _feedback;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ownsFeedbackService = widget.feedbackService == null;
    _feedbackService = widget.feedbackService ?? GeminiFeedbackService();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feedback = await _feedbackService.generateFeedback(widget.payload);
      if (!mounted) return;

      setState(() {
        _feedback = feedback;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  void dispose() {
    if (_ownsFeedbackService) {
      _feedbackService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    final applicantInfo = widget.payload.applicantInfo;
    final interviewTitle = applicantInfo?.position.isNotEmpty == true
        ? applicantInfo!.position
        : applicantInfo?.companyName.isNotEmpty == true
        ? applicantInfo!.companyName
        : '면접';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          '면접 피드백',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeedbackHeader(
                title: interviewTitle,
                exchangeCount: widget.payload.exchanges.length,
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const _LoadingFeedbackCard()
              else if (_errorMessage != null)
                _FeedbackErrorCard(
                  message: _errorMessage!,
                  onRetry: _loadFeedback,
                )
              else if (feedback != null) ...[
                _ScoreSummaryCard(feedback: feedback),
                const SizedBox(height: 16),
                _FeedbackSection(
                  title: '강점',
                  icon: Icons.thumb_up_alt_rounded,
                  items: feedback.strengths,
                  fallback: '답변 흐름을 끝까지 유지했습니다.',
                ),
                const SizedBox(height: 16),
                _FeedbackSection(
                  title: '개선점',
                  icon: Icons.tips_and_updates_rounded,
                  items: feedback.improvements,
                  fallback: '답변마다 수치, 역할, 결과를 더 구체적으로 말해보세요.',
                ),
                const SizedBox(height: 16),
                Text(
                  '문항별 피드백',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                for (final item in feedback.questionFeedback) ...[
                  _QuestionFeedbackCard(feedback: item),
                  const SizedBox(height: 12),
                ],
                _NextGoalCard(goal: feedback.nextPracticeGoal),
              ],
              const SizedBox(height: 18),
              _InterviewHistory(exchanges: widget.payload.exchanges),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.goNamed(OnboardingScreen.routeName),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 연습하기'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackHeader extends StatelessWidget {
  const _FeedbackHeader({required this.title, required this.exchangeCount});

  final String title;
  final int exchangeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFF0EFFF),
            child: Icon(
              Icons.insights_rounded,
              color: Color(0xFF6C63FF),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '질문/답변 $exchangeCount개를 분석했습니다',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
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

class _LoadingFeedbackCard extends StatelessWidget {
  const _LoadingFeedbackCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'AI가 면접 답변을 분석하고 있습니다...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackErrorCard extends StatelessWidget {
  const _FeedbackErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '피드백 생성 실패',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('다시 생성'),
          ),
        ],
      ),
    );
  }
}

class _ScoreSummaryCard extends StatelessWidget {
  const _ScoreSummaryCard({required this.feedback});

  final InterviewFeedbackResult feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Text(
              '${feedback.score}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6C63FF),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '종합 피드백',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.fallback,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final displayItems = items.isEmpty ? [fallback] : items;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in displayItems) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (item != displayItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _QuestionFeedbackCard extends StatelessWidget {
  const _QuestionFeedbackCard({required this.feedback});

  final InterviewQuestionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText(label: '질문', text: feedback.question),
          const SizedBox(height: 10),
          _LabelText(label: '답변', text: feedback.answer),
          const SizedBox(height: 10),
          _LabelText(label: '피드백', text: feedback.feedback),
          const SizedBox(height: 10),
          _LabelText(label: '개선 예시', text: feedback.suggestion),
        ],
      ),
    );
  }
}

class _NextGoalCard extends StatelessWidget {
  const _NextGoalCard({required this.goal});

  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: _LabelText(label: '다음 연습 목표', text: goal),
    );
  }
}

class _InterviewHistory extends StatelessWidget {
  const _InterviewHistory({required this.exchanges});

  final List<InterviewExchange> exchanges;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '질문/답변 기록',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in exchanges.asMap().entries) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${entry.key + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 8),
                _LabelText(label: '질문', text: entry.value.question),
                const SizedBox(height: 8),
                _LabelText(label: '답변', text: entry.value.answer),
              ],
            ),
          ),
          if (entry.key != exchanges.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}
