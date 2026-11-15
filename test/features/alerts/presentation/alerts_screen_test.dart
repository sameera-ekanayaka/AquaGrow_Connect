import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/simulation/in_memory_alert_repository.dart';
import 'package:aquagrow_mobile/features/alerts/application/alerts_providers.dart';
import 'package:aquagrow_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PodAlert alert(
  String id,
  String title,
  DateTime at, {
  SensorStatus? severity,
}) =>
    PodAlert(
      id: id,
      podId: 'pod-alpha',
      metric: SensorMetric.ph,
      severity: severity ?? SensorStatus.critical,
      title: title,
      message: 'Pod Alpha reads pH 4.8.',
      value: 4.8,
      createdAt: at,
    );

void main() {
  late InMemoryAlertRepository repo;

  setUp(() => repo = InMemoryAlertRepository());
  tearDown(() => repo.dispose());

  Future<void> pumpAlerts(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertRepositoryProvider.overrideWithValue(repo),
          alertsClockProvider
              .overrideWithValue(() => DateTime(2026, 11, 15, 10)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AlertsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the empty state and no Mark all read button',
      (tester) async {
    await pumpAlerts(tester);

    expect(find.text('No alerts'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('groups alerts into Today and Earlier', (tester) async {
    await repo
        .add(alert('old', 'Water level is low', DateTime(2026, 11, 13, 9)));
    await repo.add(alert('new', 'pH is too low', DateTime(2026, 11, 15, 9)));
    await pumpAlerts(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    final todayY = tester.getTopLeft(find.text('Today')).dy;
    final newY = tester.getTopLeft(find.text('pH is too low')).dy;
    final earlierY = tester.getTopLeft(find.text('Earlier')).dy;
    final oldY = tester.getTopLeft(find.text('Water level is low')).dy;
    expect(todayY < newY && newY < earlierY && earlierY < oldY, isTrue);
  });

  testWidgets('swiping an alert marks it read and keeps it in the list',
      (tester) async {
    await repo.add(alert('a1', 'pH is too low', DateTime(2026, 11, 15, 9)));
    await pumpAlerts(tester);
    expect(find.text('Mark all read'), findsOneWidget);

    await tester.drag(find.text('pH is too low'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    final stored = await repo.watchAlerts().first;
    expect(stored.single.acknowledged, isTrue);
    expect(find.text('pH is too low'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('Mark all read acknowledges every alert', (tester) async {
    await repo.add(alert('a1', 'pH is too low', DateTime(2026, 11, 15, 9)));
    await repo.add(
      alert(
        'a2',
        'Water is too warm',
        DateTime(2026, 11, 15, 9, 30),
        severity: SensorStatus.warning,
      ),
    );
    await pumpAlerts(tester);

    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    await tester.pump();

    final stored = await repo.watchAlerts().first;
    expect(stored.every((a) => a.acknowledged), isTrue);
  });
}
