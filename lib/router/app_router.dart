import 'package:go_router/go_router.dart';

import '../models/applicant_info.dart';
import '../models/interview_feedback.dart';
import '../screens/feedback_screen.dart';
import '../screens/interview_screen.dart';
import '../screens/onboarding_screen.dart';

final GoRouter router = appRouter();

GoRouter appRouter() {
  return GoRouter(
    initialLocation: OnboardingScreen.routePath,
    routes: [
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        builder: (context, state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: InterviewScreen.routePath,
        name: InterviewScreen.routeName,
        builder: (context, state) {
          final applicantInfo = state.extra is ApplicantInfo
              ? state.extra as ApplicantInfo
              : null;

          return InterviewScreen(applicantInfo: applicantInfo);
        },
      ),
      GoRoute(
        path: FeedbackScreen.routePath,
        name: FeedbackScreen.routeName,
        builder: (context, state) {
          final payload = state.extra is InterviewFeedbackPayload
              ? state.extra as InterviewFeedbackPayload
              : null;

          if (payload == null) {
            return const OnboardingScreen();
          }

          return FeedbackScreen(payload: payload);
        },
      ),
    ],
  );
}
