import 'package:flutter_test/flutter_test.dart';
import 'package:your_ai_nterviewer/models/applicant_info.dart';
import 'package:your_ai_nterviewer/services/interview_prompt_builder.dart';

void main() {
  test('build includes selected interview context', () {
    const applicantInfo = ApplicantInfo(
      companyName: '기술 면접',
      position: '기술 면접',
      interviewerName: '지혜',
      interviewerRivePath: 'assets/rives/jihye_anchor.riv',
      interviewerStyle: '실무형',
      interviewGoal: '프로젝트 설명',
    );

    final prompt = InterviewPromptBuilder.build(applicantInfo);

    expect(prompt, contains('전문 AI 면접관'));
    expect(prompt, contains('면접 유형: 기술 면접'));
    expect(prompt, contains('면접관 스타일: 실무형'));
    expect(prompt, contains('면접 목표: 프로젝트 설명'));
    expect(prompt, contains('한 번에 하나의 꼬리질문'));
  });
}
