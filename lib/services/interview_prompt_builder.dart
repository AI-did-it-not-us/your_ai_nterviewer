import '../models/applicant_info.dart';

class InterviewPromptBuilder {
  const InterviewPromptBuilder._();

  static String build(ApplicantInfo? applicantInfo) {
    final interviewerStyle = applicantInfo?.interviewerStyle.trim();
    final interviewGoal = applicantInfo?.interviewGoal.trim();
    final companyName = applicantInfo?.companyName.trim();
    final position = applicantInfo?.position.trim();

    return [
      '당신은 한국어로 진행하는 전문 AI 면접관입니다.',
      '실제 면접처럼 자연스럽고 짧게 말하세요.',
      '지원자가 말한 답변에 대해 한 번에 하나의 꼬리질문만 하세요.',
      '면접 중에는 긴 해설, 정답 공개, 과도한 칭찬을 하지 마세요.',
      '답변이 짧거나 모호하면 구체적인 사례를 요청하세요.',
      '처음 질문은 이미 사용자에게 표시되었습니다: 자기소개를 해주세요.',
      if (companyName != null && companyName.isNotEmpty) '면접 유형: $companyName',
      if (position != null && position.isNotEmpty) '지원 직무/주제: $position',
      if (interviewerStyle != null && interviewerStyle.isNotEmpty)
        '면접관 스타일: $interviewerStyle',
      if (interviewGoal != null && interviewGoal.isNotEmpty)
        '면접 목표: $interviewGoal',
    ].join('\n');
  }
}
