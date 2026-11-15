import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/onboarding/application/onboarding_store.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryPreferencesStore prefs;
  late int finished;

  setUp(() {
    prefs = InMemoryPreferencesStore();
    finished = 0;
  });

  bool seen() => OnboardingStore(prefs).isSeen;

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    ThemeData? theme,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesStoreProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          home: OnboardingScreen(onFinished: () => finished++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the first slide with Skip and Next', (tester) async {
    await pumpOnboarding(tester);

    expect(find.text('Grow fresh food at home'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
  });

  testWidgets('Next walks through the slides to Get started', (tester) async {
    await pumpOnboarding(tester);

    await tapNext(tester);
    expect(find.text('Know your plants live'), findsOneWidget);
    expect(find.text('6.2'), findsOneWidget);

    await tapNext(tester);
    expect(find.text("Get alerted before it's too late"), findsOneWidget);
    expect(find.text('Water needs attention'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(
      tester
          .widget<Visibility>(
            find.ancestor(
              of: find.text('Skip'),
              matching: find.byType(Visibility),
            ),
          )
          .visible,
      isFalse,
    );
    expect(seen(), isFalse);
  });

  testWidgets('Get started saves the walkthrough as seen', (tester) async {
    await pumpOnboarding(tester);
    await tapNext(tester);
    await tapNext(tester);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(seen(), isTrue);
    expect(finished, 1);
  });

  testWidgets('Skip saves it as seen straight away', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(seen(), isTrue);
    expect(finished, 1);
  });

  testWidgets('swiping also turns the page', (tester) async {
    await pumpOnboarding(tester);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Know your plants live'), findsOneWidget);
  });

  testWidgets('fits a 360 dp phone and works in dark mode', (tester) async {
    await pumpOnboarding(
      tester,
      theme: AppTheme.dark,
      size: const Size(360, 640),
    );

    for (var i = 0; i < 2; i++) {
      await tapNext(tester);
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('splash shows the AquaGrow Connect wordmark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );

    expect(find.bySemanticsLabel('AquaGrow Connect'), findsOneWidget);
    expect(find.text('AquaGrow'), findsOneWidget);
  });
}
