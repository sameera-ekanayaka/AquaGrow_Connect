import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/simulator/presentation/simulator_panel_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PodSimulator sim;

  setUp(() => sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10)));
  tearDown(() => sim.dispose());

  Future<void> pumpPanel(
    WidgetTester tester, {
    ThemeData? theme,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [podSimulatorProvider.overrideWithValue(sim)],
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          home: const SimulatorPanelScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> trigger(WidgetTester tester, SimScenario scenario) async {
    await tester.tap(find.text(scenario.label));
    sim.tick();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows live pH, water level and temperature at the top',
      (tester) async {
    await pumpPanel(tester);

    expect(find.text('pH'), findsOneWidget);
    expect(find.text('Water level'), findsOneWidget);
    expect(find.text('Water temp'), findsOneWidget);
    expect(find.text('In range'), findsNWidgets(3));
  });

  testWidgets('groups scenarios as Water, Nutrients and Device',
      (tester) async {
    await pumpPanel(tester);

    for (final title in ['Water', 'Nutrients', 'Device']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Pod is healthy'), findsOneWidget);
  });

  testWidgets('a pH crash shows on the panel straight away', (tester) async {
    await pumpPanel(tester);

    await trigger(tester, SimScenario.acidSpike);

    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('pH crash applied'), findsOneWidget);
  });

  testWidgets('reset puts the pod back to healthy', (tester) async {
    await pumpPanel(tester);
    await trigger(tester, SimScenario.lowWater);
    expect(find.text('Reset to healthy pod'), findsOneWidget);

    await tester.tap(find.text('Reset to healthy pod'));
    sim.tick();
    await tester.pump();
    await tester.pump();

    expect(sim.scenarioOf('pod-alpha'), SimScenario.normal);
    expect(find.text('Pod is healthy'), findsOneWidget);
  });

  testWidgets('an offline pod says so instead of grading old values',
      (tester) async {
    await pumpPanel(tester);

    await trigger(tester, SimScenario.sensorOffline);

    expect(find.text('Offline'), findsNWidgets(3));
  });

  testWidgets('fits a 360 dp phone in dark mode', (tester) async {
    await pumpPanel(tester, theme: AppTheme.dark, width: 360);

    expect(tester.takeException(), isNull);
    expect(find.text('Water temp'), findsOneWidget);
  });
}
