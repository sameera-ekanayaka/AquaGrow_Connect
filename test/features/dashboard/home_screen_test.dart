import 'package:aquagrow_mobile/app/app.dart';
import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_service.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/features/dashboard/application/home_clock.dart';
import 'package:aquagrow_mobile/features/onboarding/application/onboarding_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 15, 10);

void main() {
  late PodSimulator sim;

  setUp(() => sim = PodSimulator(clock: () => _now));
  tearDown(() => sim.dispose());

  Future<void> pumpHome(WidgetTester tester) async {
    // A tall phone, so every Home section is built without scrolling.
    tester.view.physicalSize = const Size(1170, 7200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      // The same scope as testApp(), plus a fixed clock for "Updated" text.
      ProviderScope(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(user: testUser)),
          podSimulatorProvider.overrideWithValue(sim),
          isOfflineProvider.overrideWith((ref) => Stream.value(false)),
          notificationServiceProvider
              .overrideWithValue(FakeNotificationService()),
          // Onboarding already seen, so the app opens on Home.
          preferencesStoreProvider.overrideWithValue(
            InMemoryPreferencesStore()
              ..setBool(OnboardingStore.seenKey, value: true),
          ),
          homeClockProvider.overrideWithValue(() => _now),
        ],
        child: const AquaGrowApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the pod, crop hero, readings and plants', (tester) async {
    await pumpHome(tester);

    expect(find.text('Pod Alpha'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Day 9 · Growing'), findsOneWidget);
    expect(find.text('Harvest in about 20 days'), findsOneWidget);
    // Hero and the Your plants tile.
    expect(find.text('Genovese Basil'), findsNWidgets(2));
    expect(find.text('Baby Spinach'), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('6.2'), findsOneWidget);
    expect(find.text('View crops'), findsOneWidget);
    expect(find.text('Pod controls'), findsOneWidget);
    expect(find.text('Water pump'), findsOneWidget);
  });

  testWidgets('an out-of-range tile says which way in words', (tester) async {
    await pumpHome(tester);
    expect(find.text('Target 5.5–6.5'), findsOneWidget);

    sim.applyScenario('pod-alpha', SimScenario.acidSpike);
    await tester.pump();

    expect(find.text('Too low · Target 5.5–6.5'), findsOneWidget);
  });

  testWidgets('no task card while every reading is in range', (tester) async {
    await pumpHome(tester);

    expect(find.text('Mark as refilled'), findsNothing);
  });

  testWidgets('low water shows the task and refilling clears it',
      (tester) async {
    await pumpHome(tester);
    sim.applyScenario('pod-alpha', SimScenario.lowWater);
    await tester.pump();

    expect(find.text('Water is very low'), findsOneWidget);
    expect(find.text('Pod Alpha is at 12%. Refill it now.'), findsOneWidget);

    await tester.tap(find.text('Mark as refilled'));
    await tester.pumpAndSettle();
    expect(find.text('Mark Pod Alpha as refilled?'), findsOneWidget);

    await tester.tap(find.text('Mark refilled'));
    // The simulated repository waits a moment, like real hardware.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(sim.latest('pod-alpha').waterLevelPct, 100);
    expect(find.text('Pod Alpha marked as refilled'), findsOneWidget);
    expect(find.text('Water is very low'), findsNothing);
  });

  testWidgets('cancelling the confirm dialog does not refill', (tester) async {
    await pumpHome(tester);
    sim.applyScenario('pod-alpha', SimScenario.lowWater);
    await tester.pump();

    await tester.tap(find.text('Mark as refilled'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(sim.latest('pod-alpha').waterLevelPct, 12);
    expect(find.text('Water is very low'), findsOneWidget);
  });

  testWidgets('the pod picker switches Home to another pod', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Pod Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a pod'), findsOneWidget);
    expect(find.text('Dining room · Baby Spinach'), findsOneWidget);

    await tester.tap(find.text('Pod Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a pod'), findsNothing);
    expect(find.text('Pod Beta'), findsOneWidget);
    // Baby Spinach is now the hero and still a tile.
    expect(find.text('Baby Spinach'), findsNWidgets(2));
  });

  testWidgets('an offline pod shows Offline and stale values', (tester) async {
    await pumpHome(tester);
    sim.applyScenario('pod-alpha', SimScenario.sensorOffline);
    await tester.pump();
    await tester.pump();

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Last known value'), findsNWidgets(4));
    expect(find.textContaining('Last reading'), findsOneWidget);
    expect(
      find.text('Controls come back when Pod Alpha reconnects.'),
      findsOneWidget,
    );
  });
}
