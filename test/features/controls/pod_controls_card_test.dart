import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/controls/presentation/pod_controls_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Longer than the simulated round trip to the pod.
const _roundTrip = Duration(milliseconds: 500);

void main() {
  late PodSimulator sim;

  setUp(() => sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10)));
  tearDown(() => sim.dispose());

  Future<void> pumpCard(WidgetTester tester, {Pod? pod}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          podSimulatorProvider.overrideWithValue(sim),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PodControlsCard(pod: pod ?? sim.pods.first),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool pumpOn() => sim.actuators('pod-alpha').pumpOn;

  testWidgets('tapping the pump switch asks first', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Turn the pump off?'), findsOneWidget);
    expect(find.text('Turn off'), findsOneWidget);
  });

  testWidgets('Cancel leaves the pump running', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(pumpOn(), isTrue);
    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('Confirm turns the pump off, with a spinner meanwhile',
      (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn off'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(_roundTrip);
    await tester.pump();

    expect(pumpOn(), isFalse);
    expect(find.text('Off'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a working pH-down dose says pH lowered', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Dose'));
    await tester.pumpAndSettle();
    expect(find.text('Add one pH-down pulse?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Dose'));
    await tester.pump(_roundTrip);
    await tester.pump();

    expect(find.text('pH lowered'), findsOneWidget);
  });

  testWidgets('an empty doser warns, then locks after five pulses',
      (tester) async {
    sim.applyScenario('pod-alpha', SimScenario.doserEmpty);
    await pumpCard(tester);

    Future<void> dose() async {
      await tester.tap(find.widgetWithText(OutlinedButton, 'Dose'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dose'));
      await tester.pump(_roundTrip);
      await tester.pump();
    }

    await dose();
    expect(
      find.text('No change. Check the pH-down bottle (1 of 5).'),
      findsOneWidget,
    );

    for (var i = 0; i < 4; i++) {
      await dose();
    }
    expect(find.text('Dosing locked for safety'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Dose'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('releasing the brightness slider asks before sending',
      (tester) async {
    await pumpCard(tester);
    final before = sim.actuators('pod-alpha').lightBrightness;

    await tester.drag(find.byType(Slider), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Set brightness to'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(sim.actuators('pod-alpha').lightBrightness, before);
    expect(find.text('$before%'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(RegExp(r'^Set \d+%$')));
    await tester.pump(_roundTrip);
    await tester.pump();

    expect(sim.actuators('pod-alpha').lightBrightness, lessThan(before));
  });

  testWidgets('an offline pod disables every control and says why',
      (tester) async {
    sim.applyScenario('pod-alpha', SimScenario.sensorOffline);
    await pumpCard(tester);

    expect(
      find.text('Controls come back when Pod Alpha reconnects.'),
      findsOneWidget,
    );
    expect(find.text('Pod is offline'), findsNWidgets(3));
    for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
      expect(s.onChanged, isNull);
    }
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Dose'))
          .onPressed,
      isNull,
    );
  });

  group('a live pod the controls cannot reach', () {
    Pod livePod({required bool online}) => Pod(
          id: 'live-uuid',
          name: 'Pod Gamma',
          room: 'Balcony',
          isOnline: online,
          lastSeenAt: DateTime(2026, 11, 15, 10),
        );

    testWidgets('offline: disabled controls and the reconnect note',
        (tester) async {
      await pumpCard(tester, pod: livePod(online: false));
      await tester.pump();

      expect(find.text('Something went wrong'), findsNothing);
      expect(
        find.text('Controls come back when Pod Gamma reconnects.'),
        findsOneWidget,
      );
      for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
        expect(s.onChanged, isNull);
      }
    });

    testWidgets('online: says controls are not connected yet', (tester) async {
      await pumpCard(tester, pod: livePod(online: true));
      await tester.pump();

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Controls not connected yet'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
