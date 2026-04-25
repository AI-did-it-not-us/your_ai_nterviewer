class InterviewSessionProgress {
  const InterviewSessionProgress({
    this.introExchangeCount = 1,
    this.maxFollowUpAnswers = 5,
  });

  final int introExchangeCount;
  final int maxFollowUpAnswers;

  int followUpAnswerCount(int exchangeCount) {
    final count = exchangeCount - introExchangeCount;
    return count < 0 ? 0 : count;
  }

  bool shouldFinish(int exchangeCount) {
    return followUpAnswerCount(exchangeCount) >= maxFollowUpAnswers;
  }
}
