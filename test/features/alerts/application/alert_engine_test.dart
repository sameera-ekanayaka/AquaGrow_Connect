import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/alerts/application/alert_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PodSimulator sim;
  late ProviderContainer container;

  setUp(() {
    var now = DateTime(2026, 11, 15, 10);
    sim = PodSimulator(clock: () => now = now.add(const Duration(seconds: 2)));
    container = ProviderContainer(
      overrides: [podSimulatorProvider.overrideWithValue(sim)],
    );
  });

  tearDown(() {
    container.dispose();
    sim.dispose();
  });

  /// Lets streams deliver their events.
  Future<void> settle() => Future<void>.delayed(Duration.zero)
      .then((_) => Future<void>.delayed(Duration.zero));

  Future<List<PodAlert>> alerts() =>
      container.read(alertRepositoryProvider).watchAlerts().first;

  test('watches every pod once pods load', () async {
    final engine = container.read(alertEngineProvider);
    await settle();
    expect(engine.watchedPodIds, containsAll(['pod-alpha', 'pod-beta']));
  });

  test('healthy pods raise no alerts', () async {
    container.read(alertEngineProvider);
    await settle();
    for (var i = 0; i < 20; i++) {
      sim.tick();
    }
    await settle();
    expect(await alerts(), isEmpty);
  });

  test('a pH crash raises exactly one critical "pH is too low" alert',
      () async {
    container.read(alertEngineProvider);
    await settle();

    sim.applyScenario('pod-alpha', SimScenario.acidSpike);
    for (var i = 0; i < 10; i++) {
      sim.tick();
    }
    await settle();

    final list = await alerts();
    expect(list, hasLength(1));
    expect(list.single.podId, 'pod-alpha');
    expect(list.single.metric, SensorMetric.ph);
    expect(list.single.severity, SensorStatus.critical);
    expect(list.single.title, 'pH is too low');
    expect(list.single.message, startsWith('Pod Alpha reads pH 4.8'));
  });

  test('low water on Pod Beta raises a water level alert for Pod Beta',
      () async {
    container.read(alertEngineProvider);
    await settle();

    sim.applyScenario('pod-beta', SimScenario.lowWater);
    await settle();

    final list = await alerts();
    expect(list.map((a) => a.title), contains('Water level is low'));
    expect(list.every((a) => a.podId == 'pod-beta'), isTrue);
  });
}
