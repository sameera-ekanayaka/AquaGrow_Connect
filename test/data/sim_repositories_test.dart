import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/simulation/in_memory_alert_repository.dart';
import 'package:aquagrow_mobile/data/simulation/sim_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PodSimulator sim;

  setUp(() => sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10)));
  tearDown(() => sim.dispose());

  test('watchReadings emits the latest reading first, then live ones', () async {
    final repo = SimTelemetryRepository(sim);
    final stream = repo.watchReadings('pod-alpha');

    final future = stream.take(2).toList();
    await Future<void>.delayed(Duration.zero);
    sim.tick();
    final readings = await future;

    expect(readings, hasLength(2));
    expect(readings.every((r) => r.deviceId == 'pod-alpha'), isTrue);
  });

  test('watchPods emits the pods immediately', () async {
    final pods = await SimPodRepository(sim).watchPods().first;
    expect(pods, hasLength(2));
  });

  test('control commands reach the simulator', () async {
    final repo = SimControlRepository(sim, latency: Duration.zero);

    await repo.setPump('pod-alpha', on: false);
    await repo.setLight('pod-alpha', on: true, brightness: 40);

    final state = sim.actuators('pod-alpha');
    expect(state.pumpOn, isFalse);
    expect(state.lightBrightness, 40);
  });

  test('commands fail with DeviceFailure when the pod is offline', () async {
    final repo = SimControlRepository(sim, latency: Duration.zero);
    sim.applyScenario('pod-beta', SimScenario.sensorOffline);

    expect(() => repo.setPump('pod-beta', on: false), throwsA(isA<DeviceFailure>()));
  });

  test('alert repository keeps newest first and acknowledges', () async {
    final repo = InMemoryAlertRepository();
    PodAlert alert(String id) => PodAlert(
          id: id,
          podId: 'pod-alpha',
          metric: SensorMetric.ph,
          severity: SensorStatus.critical,
          title: 'pH is too low',
          message: 'Pod Alpha reads pH 4.8.',
          value: 4.8,
          createdAt: DateTime(2026, 11, 15),
        );

    await repo.add(alert('a1'));
    await repo.add(alert('a2'));
    await repo.acknowledge('a1');

    final alerts = await repo.watchAlerts().first;
    expect(alerts.map((a) => a.id), ['a2', 'a1']);
    expect(alerts.last.acknowledged, isTrue);
    repo.dispose();
  });
}
