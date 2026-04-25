# Your AI Nterviewer

AI 면접관과 음성으로 면접을 연습하고, 면접 종료 후 질문/답변 기반 피드백을 받을 수 있는 Flutter 앱입니다.

## 주요 기능

- 온보딩에서 면접 유형, 직무/주제, 면접관 스타일, 연습 목표를 선택합니다.
- 면접 화면에서 하단 마이크 버튼으로 답변을 음성 입력합니다.
- `speech_to_text`로 사용자 음성을 텍스트화하고, Google Gemini Live API가 면접관의 꼬리질문을 음성으로 응답합니다.
- 첫 자기소개 이후 꼬리질문 답변 5개가 완료되면 피드백 페이지로 이동합니다.
- 피드백 페이지에서 전체 질문/답변 기록, 종합 점수, 강점, 개선점, 문항별 피드백, 다음 연습 목표를 확인합니다.

## 기술 스택

- Flutter / Dart
- `go_router`: 화면 라우팅
- `rive`: 면접관 캐릭터 애니메이션
- `speech_to_text`: 사용자 음성 인식
- `web_socket_channel`: Gemini Live API WebSocket 연결
- `flutter_pcm_sound`: Gemini 음성 응답 PCM 재생
- `http`: Gemini 피드백 생성 REST API 호출

## 실행 준비

### 1. Flutter 환경

프로젝트는 Dart `^3.11.5`를 사용합니다. `pubspec.lock` 기준 Flutter SDK는 `>=3.35.0` 환경에서 동작합니다.

```bash
flutter --version
flutter doctor
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. Google AI Studio API 키 준비

이 앱은 별도 백엔드 없이 클라이언트에서 Google AI API를 직접 호출합니다.

- Gemini Live API: 면접관 음성 응답
- Gemini `generateContent`: 면접 종료 후 피드백 생성

Google AI Studio에서 API 키를 발급한 뒤 실행 시 `--dart-define`으로 전달합니다.

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_GOOGLE_AI_STUDIO_API_KEY
```

API 키는 저장소에 커밋하지 마세요. 현재 구현은 클라이언트 앱에 키가 포함되는 방식이므로, 실제 배포 환경에서는 키 보호를 위해 백엔드 프록시나 별도 보안 구성이 필요합니다.

## 실행 방법

### Android

에뮬레이터 또는 실제 기기를 연결한 뒤 실행합니다.

```bash
flutter run -d android --dart-define=GEMINI_API_KEY=YOUR_GOOGLE_AI_STUDIO_API_KEY
```

Debug APK 빌드:

```bash
flutter build apk --debug --dart-define=GEMINI_API_KEY=YOUR_GOOGLE_AI_STUDIO_API_KEY
```

### iOS

iOS 시뮬레이터 또는 실제 기기를 연결한 뒤 실행합니다.

```bash
flutter run -d ios --dart-define=GEMINI_API_KEY=YOUR_GOOGLE_AI_STUDIO_API_KEY
```

iOS에서는 마이크와 음성 인식 권한 승인이 필요합니다.

## 권한

앱 실행 중 다음 권한을 사용합니다.

- 인터넷 접근: Google AI API 연결
- 마이크 접근: 사용자 답변 음성 입력
- 음성 인식: 사용자 음성을 텍스트로 변환
- 오디오 재생: AI 면접관 음성 응답 재생

Android 권한은 `android/app/src/main/AndroidManifest.xml`에, iOS 권한 설명은 `ios/Runner/Info.plist`에 정의되어 있습니다.

## 개발 명령

정적 분석:

```bash
flutter analyze
```

테스트:

```bash
flutter test
```

포맷:

```bash
dart format lib test
```

## 앱 흐름

1. 온보딩에서 면접 설정을 선택합니다.
2. 면접 화면에서 첫 질문인 자기소개에 답변합니다.
3. AI 면접관이 사용자의 답변을 바탕으로 꼬리질문을 음성으로 진행합니다.
4. 꼬리질문 답변 5개가 완료되면 피드백 화면으로 이동합니다.
5. Gemini가 질문/답변 기록을 분석해 종합 피드백을 생성합니다.

## 주요 코드 위치

- `lib/screens/onboarding_screen.dart`: 면접 설정 선택 화면
- `lib/screens/interview_screen.dart`: 음성 면접 진행 화면
- `lib/screens/feedback_screen.dart`: 면접 피드백 화면
- `lib/services/gemini_live_interview_service.dart`: Gemini Live API 음성 대화 연결
- `lib/services/gemini_feedback_service.dart`: Gemini 피드백 생성 API 호출
- `lib/models/interview_feedback.dart`: 피드백 전달/결과 모델
- `lib/router/app_router.dart`: 앱 라우팅

## 테스트 범위

현재 테스트는 다음 동작을 검증합니다.

- 면접 프롬프트에 선택한 면접 설정이 포함되는지
- 자기소개 이후 꼬리질문 5개 완료 시 종료되는지
- Gemini 피드백 API 요청/응답 파싱이 정상 동작하는지
- 피드백 화면이 생성된 피드백과 질문/답변 기록을 표시하는지
