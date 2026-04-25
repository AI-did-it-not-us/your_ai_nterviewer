import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_ai_nterviewer/models/applicant_info.dart';
import 'package:your_ai_nterviewer/models/interview_feedback.dart';
import 'package:your_ai_nterviewer/screens/feedback_screen.dart';
import 'package:your_ai_nterviewer/services/gemini_feedback_service.dart';

void main() {
  testWidgets('renders generated feedback and interview history', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackScreen(
          payload: _payload,
          feedbackService: _FakeFeedbackService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('면접 피드백'), findsOneWidget);
    expect(find.text('종합 피드백'), findsOneWidget);
    expect(find.text('답변 구조가 안정적입니다.'), findsOneWidget);
    expect(find.text('질문/답변 기록'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('자기소개를 해주세요'),
      ),
      findsWidgets,
    );
  });
}

class _FakeFeedbackService implements InterviewFeedbackGenerator {
  @override
  bool get hasApiKey => true;

  @override
  Future<InterviewFeedbackResult> generateFeedback(
    InterviewFeedbackPayload payload,
  ) async {
    return const InterviewFeedbackResult(
      summary: '답변 구조가 안정적입니다.',
      score: 82,
      strengths: ['핵심 경험을 언급했습니다.'],
      improvements: ['성과 수치를 더하세요.'],
      questionFeedback: [
        InterviewQuestionFeedback(
          question: '자기소개를 해주세요.',
          answer: '안녕하세요.',
          feedback: '간결합니다.',
          suggestion: '대표 프로젝트를 덧붙이세요.',
        ),
      ],
      nextPracticeGoal: '성과 중심으로 답변하기',
    );
  }

  @override
  void dispose() {}
}

const _payload = InterviewFeedbackPayload(
  applicantInfo: ApplicantInfo(
    companyName: '기술 면접',
    position: 'Flutter 개발자',
    interviewerName: '지혜',
    interviewerRivePath: 'assets/rives/jihye_anchor.riv',
    interviewerStyle: '실무형',
    interviewGoal: '프로젝트 설명',
  ),
  exchanges: [InterviewExchange(question: '자기소개를 해주세요.', answer: '안녕하세요.')],
);
