import 'package:aquagrow_mobile/app/router/app_router.dart';
import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/pill_nav_bar.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('authRedirect on first launch', () {
    test('opens onboarding before anything else', () {
      for (final location in [AppRoutes.home, AppRoutes.login, AppRoutes.crops]) {
        expect(
          authRedirect(
            isRestored: true,
            isSignedIn: false,
            onboardingSeen: false,
            location: location,
          ),
          AppRoutes.onboarding,
        );
      }
    });

    test('stays on onboarding while it is not finished', () {
      expect(
        authRedirect(
          isRestored: true,
          isSignedIn: true,
          onboardingSeen: false,
          location: AppRoutes.onboarding,
        ),
        isNull,
      );
    });

    test('leaves onboarding once it is seen', () {
      expect(
        authRedirect(isRestored: true, isSignedIn: false, location: AppRoutes.onboarding),
        AppRoutes.login,
      );
      expect(
        authRedirect(isRestored: true, isSignedIn: true, location: AppRoutes.onboarding),
        AppRoutes.home,
      );
    });

    test('waits for the saved session before deciding', () {
      expect(
        authRedirect(
          isRestored: false,
          isSignedIn: false,
          onboardingSeen: false,
          location: AppRoutes.home,
        ),
        isNull,
      );
    });
  });

  group('First launch in the app', () {
    late PodSimulator sim;

    setUp(() => sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10)));
    tearDown(() => sim.dispose());

    testWidgets('shows the splash while the saved session loads', (tester) async {
      await tester.pumpWidget(testApp(sim: sim));

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Your garden'), findsOneWidget);
    });

    testWidgets('a new install sees onboarding, then Skip goes to sign in', (tester) async {
      await tester.pumpWidget(testApp(sim: sim, signedIn: false, onboardingSeen: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Grow fresh food at home'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Use demo account'), findsOneWidget);
    });

    testWidgets('a returning user skips onboarding', (tester) async {
      await tester.pumpWidget(testApp(sim: sim, signedIn: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(PillNavBar), findsNothing);
      expect(find.text('Use demo account'), findsOneWidget);
    });
  });
}
