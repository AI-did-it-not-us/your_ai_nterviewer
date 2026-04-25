class ApplicantInfo {
  const ApplicantInfo({
    required this.companyName,
    this.position = '',
    required this.interviewerName,
    required this.interviewerRivePath,
    required this.interviewerStyle,
    required this.interviewGoal,
  });

  final String companyName;
  final String position;
  final String interviewerName;
  final String interviewerRivePath;
  final String interviewerStyle;
  final String interviewGoal;
}
