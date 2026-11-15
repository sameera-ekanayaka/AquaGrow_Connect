import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';
import 'package:aquagrow_mobile/features/simulator/domain/scenario_groups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every scenario but the reset sits in exactly one group', () {
    final grouped = [for (final g in ScenarioGroup.values) ...g.scenarios];

    expect(grouped.toSet().length, grouped.length);
    expect(
      grouped.toSet(),
      SimScenario.values.where((s) => s != resetScenario).toSet(),
    );
  });

  test('groups are Water, Nutrients and Device', () {
    expect(ScenarioGroup.values.map((g) => g.label), [
      'Water',
      'Nutrients',
      'Device',
    ]);
    expect(ScenarioGroup.water.scenarios, contains(SimScenario.lowWater));
    expect(ScenarioGroup.nutrients.scenarios, contains(SimScenario.acidSpike));
    expect(ScenarioGroup.device.scenarios, contains(SimScenario.sensorOffline));
  });

  test('status words are plain', () {
    expect(statusInWords(SensorStatus.normal), 'In range');
    expect(statusInWords(SensorStatus.warning), 'Needs attention');
    expect(statusInWords(SensorStatus.critical), 'Critical');
  });
}
