enum GeminiLiveInterviewStatus {
  idle,
  connecting,
  ready,
  waitingResponse,
  speaking,
  error,
}

extension GeminiLiveInterviewStatusLabel on GeminiLiveInterviewStatus {
  String get label {
    return switch (this) {
      GeminiLiveInterviewStatus.idle => '대기 중',
      GeminiLiveInterviewStatus.connecting => 'Gemini 연결 중',
      GeminiLiveInterviewStatus.ready => '답변 가능',
      GeminiLiveInterviewStatus.waitingResponse => '면접관 응답 생성 중',
      GeminiLiveInterviewStatus.speaking => '면접관 답변 중',
      GeminiLiveInterviewStatus.error => '오류',
    };
  }
}

class GeminiLiveInterviewState {
  const GeminiLiveInterviewState({
    this.status = GeminiLiveInterviewStatus.idle,
    this.isAiSpeaking = false,
    this.currentResponseText = '',
    this.errorMessage,
  });

  final GeminiLiveInterviewStatus status;
  final bool isAiSpeaking;
  final String currentResponseText;
  final String? errorMessage;

  bool get isBusy {
    return switch (status) {
      GeminiLiveInterviewStatus.connecting ||
      GeminiLiveInterviewStatus.waitingResponse ||
      GeminiLiveInterviewStatus.speaking => true,
      _ => false,
    };
  }

  GeminiLiveInterviewState copyWith({
    GeminiLiveInterviewStatus? status,
    bool? isAiSpeaking,
    String? currentResponseText,
    Object? errorMessage = _unchanged,
  }) {
    return GeminiLiveInterviewState(
      status: status ?? this.status,
      isAiSpeaking: isAiSpeaking ?? this.isAiSpeaking,
      currentResponseText: currentResponseText ?? this.currentResponseText,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();
