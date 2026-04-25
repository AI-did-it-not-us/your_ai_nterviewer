import 'package:go_router/go_router.dart';

import '../models/applicant_info.dart';
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
    ],
  );
}
