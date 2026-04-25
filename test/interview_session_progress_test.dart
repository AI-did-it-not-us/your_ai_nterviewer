import 'package:flutter_test/flutter_test.dart';
import 'package:your_ai_nterviewer/models/interview_session_progress.dart';

void main() {
  test('does not finish after introduction answer only', () {
    const progress = InterviewSessionProgress();

    expect(progress.followUpAnswerCount(1), 0);
    expect(progress.shouldFinish(1), isFalse);
  });

  test('finishes after five follow-up answers', () {
    const progress = InterviewSessionProgress();

    expect(progress.followUpAnswerCount(5), 4);
    expect(progress.shouldFinish(5), isFalse);
    expect(progress.followUpAnswerCount(6), 5);
    expect(progress.shouldFinish(6), isTrue);
  });
}
