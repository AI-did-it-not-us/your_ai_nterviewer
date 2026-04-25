import 'applicant_info.dart';

class InterviewExchange {
  const InterviewExchange({required this.question, required this.answer});

  final String question;
  final String answer;
}

class InterviewFeedbackPayload {
  const InterviewFeedbackPayload({
    required this.applicantInfo,
    required this.exchanges,
  });

  final ApplicantInfo? applicantInfo;
  final List<InterviewExchange> exchanges;
}

class InterviewFeedbackResult {
  const InterviewFeedbackResult({
    required this.summary,
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.questionFeedback,
    required this.nextPracticeGoal,
  });

  final String summary;
  final int score;
  final List<String> strengths;
  final List<String> improvements;
  final List<InterviewQuestionFeedback> questionFeedback;
  final String nextPracticeGoal;

  factory InterviewFeedbackResult.fromJson(Map<String, dynamic> json) {
    return InterviewFeedbackResult(
      summary: _readString(json['summary'], fallback: '면접 답변을 정리했습니다.'),
      score: _readInt(json['score']).clamp(0, 100),
      strengths: _readStringList(json['strengths']),
      improvements: _readStringList(json['improvements']),
      questionFeedback: _readQuestionFeedback(json['questionFeedback']),
      nextPracticeGoal: _readString(
        json['nextPracticeGoal'],
        fallback: '다음 연습에서는 답변마다 구체적인 사례를 하나씩 더해보세요.',
      ),
    );
  }
}

class InterviewQuestionFeedback {
  const InterviewQuestionFeedback({
    required this.question,
    required this.answer,
    required this.feedback,
    required this.suggestion,
  });

  final String question;
  final String answer;
  final String feedback;
  final String suggestion;

  factory InterviewQuestionFeedback.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionFeedback(
      question: _readString(json['question']),
      answer: _readString(json['answer']),
      feedback: _readString(json['feedback'], fallback: '답변을 확인했습니다.'),
      suggestion: _readString(
        json['suggestion'],
        fallback: '조금 더 구체적으로 답변해보세요.',
      ),
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<InterviewQuestionFeedback> _readQuestionFeedback(Object? value) {
  if (value is! List) return const [];

  return value
      .whereType<Map<String, dynamic>>()
      .map(InterviewQuestionFeedback.fromJson)
      .toList(growable: false);
}
