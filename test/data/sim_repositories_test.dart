import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/new_pod.dart';
import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/simulation/in_memory_alert_repository.dart';
import 'package:aquagrow_mobile/data/simulation/sim_repositories.dart';
import 'package:aquagrow_mobile/features/crops/domain/crop_recipes.dart';
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

    await expectLater(repo.setPump('pod-beta', on: false), throwsA(isA<DeviceFailure>()));
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

  test('addPod adds an empty pod and rejects a used serial number', () async {
    final repo = SimPodRepository(sim);
    final pod = await repo.addPod(
      NewPod(name: ' Pod Gamma ', room: 'Balcony', serialNumber: 'aqg-2026-0042', systemType: PodSystemType.nft),
    );

    expect(pod.name, 'Pod Gamma');
    expect(pod.batch, isNull);
    expect((await repo.getPods()).map((p) => p.id), contains(pod.id));

    await expectLater(
      repo.addPod(
        NewPod(name: 'Another', room: 'Hall', serialNumber: 'AQG-2026-0042', systemType: PodSystemType.dwc),
      ),
      throwsA(
        isA<ValidationFailure>().having((f) => f.message, 'message', 'This serial number is already registered.'),
      ),
    );
  });

  test('plantCrop fills an empty pod and harvest empties it again', () async {
    final repo = SimPodRepository(sim);
    final pod = await repo.addPod(
      NewPod(name: 'Pod Gamma', room: 'Balcony', serialNumber: 'AQG-1', systemType: PodSystemType.nft),
    );

    await repo.plantCrop(pod.id, CropRecipes.findForCrop('Genovese Basil'));
    var planted = (await repo.getPods()).firstWhere((p) => p.id == pod.id);
    expect(planted.batch?.cropName, 'Genovese Basil');
    expect(planted.batch?.daysToHarvest, 28);
    expect(planted.batch?.plantedAt, DateTime(2026, 11, 15));

    await expectLater(
      repo.plantCrop(pod.id, CropRecipes.findForCrop('Baby Spinach')),
      throwsA(isA<ValidationFailure>()),
    );

    await repo.harvest(pod.id);
    planted = (await repo.getPods()).firstWhere((p) => p.id == pod.id);
    expect(planted.batch, isNull);
  });

  test('deletePod removes the pod for this session', () async {
    final repo = SimPodRepository(sim);
    await repo.deletePod('pod-beta');
    expect((await repo.getPods()).map((p) => p.id), ['pod-alpha']);
  });
}
