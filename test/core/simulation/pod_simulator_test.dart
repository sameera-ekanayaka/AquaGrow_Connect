import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late PodSimulator sim;

  setUp(() {
    now = DateTime(2026, 11, 15, 10);
    sim = PodSimulator(clock: () => now);
  });

  tearDown(() => sim.dispose());

  test('starts with the two demo pods and their crops', () {
    expect(sim.pods.map((p) => p.name), ['Pod Alpha', 'Pod Beta']);
    final alpha = sim.pods.first;
    expect(alpha.isOnline, isTrue);
    expect(alpha.batch?.cropName, 'Genovese Basil');
    expect(alpha.batch?.stage(now), GrowthStage.growing);
  });

  test('tick emits one reading per online pod', () async {
    final received = <SensorReading>[];
    final sub = sim.readings.listen(received.add);

    sim.tick();
    await Future<void>.delayed(Duration.zero);

    expect(received.map((r) => r.deviceId), ['pod-alpha', 'pod-beta']);
    await sub.cancel();
  });

  test('healthy readings stay in their target range over time', () {
    for (var i = 0; i < 200; i++) {
      sim.tick();
    }
    final r = sim.latest('pod-alpha');
    expect(SensorMetric.ph.statusOf(r.ph), SensorStatus.normal);
    expect(SensorMetric.ec.statusOf(r.ecMs), SensorStatus.normal);
    expect(SensorMetric.waterTemp.statusOf(r.waterTempC), SensorStatus.normal);
  });

  test('acid spike makes pH critical', () {
    sim.applyScenario('pod-alpha', SimScenario.acidSpike);
    sim.tick();
    expect(SensorMetric.ph.statusOf(sim.latest('pod-alpha').ph), SensorStatus.critical);
  });

  test('pH-down pulse lowers pH by one step', () {
    sim.applyScenario('pod-alpha', SimScenario.alkalineDrift);
    final before = sim.latest('pod-alpha').ph;

    final result = sim.dosePhDown('pod-alpha');

    expect(result, PhDoseResult.applied);
    expect(sim.latest('pod-alpha').ph, closeTo(before - PodSimulator.phDoseStep, 0.001));
  });

  test('empty doser locks dosing after the maximum failed pulses', () {
    sim.applyScenario('pod-alpha', SimScenario.doserEmpty);

    final results = [
      for (var i = 0; i < ActuatorState.maxDosesWithoutChange; i++) sim.dosePhDown('pod-alpha'),
    ];

    expect(results.first, PhDoseResult.noEffect);
    expect(results.last, PhDoseResult.locked);
    expect(sim.actuators('pod-alpha').dosingLocked, isTrue);
    expect(sim.dosePhDown('pod-alpha'), PhDoseResult.locked);

    sim.applyScenario('pod-alpha', SimScenario.normal);
    expect(sim.actuators('pod-alpha').dosingLocked, isFalse);
  });

  test('water level drops while the pump runs and refill restores it', () {
    final start = sim.latest('pod-alpha').waterLevelPct;
    for (var i = 0; i < 50; i++) {
      sim.tick();
    }
    expect(sim.latest('pod-alpha').waterLevelPct, lessThan(start));

    sim.refillWater('pod-alpha');
    expect(sim.latest('pod-alpha').waterLevelPct, 100);
  });

  test('turning the pump off warms the water', () {
    sim.setPump('pod-alpha', on: false);
    for (var i = 0; i < 100; i++) {
      sim.tick();
    }
    expect(sim.latest('pod-alpha').waterTempC, greaterThan(24));
    expect(sim.actuators('pod-alpha').pumpOn, isFalse);
  });

  test('offline pod stops reporting and shows as offline', () async {
    final received = <SensorReading>[];
    final sub = sim.readings.listen(received.add);

    sim.applyScenario('pod-beta', SimScenario.sensorOffline);
    sim.tick();
    await Future<void>.delayed(Duration.zero);

    expect(received.where((r) => r.deviceId == 'pod-beta'), isEmpty);
    expect(sim.pods.last.isOnline, isFalse);
    await sub.cancel();
  });

  test('history has hourly points for the past week before launch', () {
    final points = sim.history(
      'pod-alpha',
      from: now.subtract(const Duration(days: 7)),
      to: now,
    );

    expect(points.length, 7 * 24);
    expect(points.first.recordedAt.isBefore(points.last.recordedAt), isTrue);
    for (final p in points) {
      expect(SensorMetric.ph.statusOf(p.ph), isNot(SensorStatus.critical));
    }
  });

  test('history is the same on every launch', () {
    final other = PodSimulator(clock: () => now);
    final range = (from: now.subtract(const Duration(days: 1)), to: now);

    final a = sim.history('pod-alpha', from: range.from, to: range.to);
    final b = other.history('pod-alpha', from: range.from, to: range.to);

    expect(a.map((r) => r.ph), b.map((r) => r.ph));
    other.dispose();
  });

  test('unknown pod id throws', () {
    expect(() => sim.latest('nope'), throwsArgumentError);
  });

  test('both demo pods have a crop photo that ships with the app', () {
    for (final seed in SimPodSeed.demo) {
      expect(
        seed.imageAsset,
        startsWith('assets/images/crops/'),
        reason: seed.id,
      );
    }
  });

  group('addPod', () {
    test('adds an empty pod that reports like the demo pods', () async {
      final pods = sim.podsStream.first;
      final pod = sim.addPod(name: 'Pod Gamma', room: 'Balcony', serialNumber: 'aqg-2026-0042');

      expect(pod.id, 'pod-aqg-2026-0042');
      expect(pod.name, 'Pod Gamma');
      expect(pod.room, 'Balcony');
      expect(pod.batch, isNull);
      expect(pod.isOnline, isTrue);
      expect((await pods).map((p) => p.id), contains(pod.id));
      expect(sim.pods, hasLength(3));

      final reading = sim.readings.firstWhere((r) => r.deviceId == pod.id);
      sim.tick();
      expect((await reading).ph, closeTo(6.0, 0.2));
    });

    test('rejects a serial number already added, in any case', () {
      sim.addPod(name: 'Pod Gamma', room: 'Balcony', serialNumber: 'AQG-1');

      expect(sim.hasSerial(' aqg-1 '), isTrue);
      expect(() => sim.addPod(name: 'Other', room: 'Hall', serialNumber: 'aqg-1'), throwsArgumentError);
      expect(sim.pods, hasLength(3));
    });
  });
}
