import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';

/// How the simulator panel groups its scenarios, so the presenter finds the
/// right one quickly during the demo.
enum ScenarioGroup {
  /// Water level and water temperature.
  water('Water', [SimScenario.lowWater, SimScenario.heatwave]),

  /// pH and EC in the nutrient solution.
  nutrients('Nutrients', [
    SimScenario.acidSpike,
    SimScenario.alkalineDrift,
    SimScenario.nutrientDepletion,
  ]),

  /// Hardware faults: the doser and the pod's connection.
  device('Device', [SimScenario.doserEmpty, SimScenario.sensorOffline]);

  const ScenarioGroup(this.label, this.scenarios);

  /// Section title on the panel.
  final String label;

  /// Scenarios in this group, in the order shown.
  final List<SimScenario> scenarios;
}

/// The scenario that puts a pod back to healthy. It is a reset button on
/// the panel, not part of any [ScenarioGroup].
const resetScenario = SimScenario.normal;

/// Metrics shown live at the top of the panel, so the audience sees a
/// scenario take effect.
const panelMetrics = [
  SensorMetric.ph,
  SensorMetric.waterLevel,
  SensorMetric.waterTemp,
];

/// The status of a reading in words, for the tiles at the top of the panel.
String statusInWords(SensorStatus status) => switch (status) {
      SensorStatus.normal => 'In range',
      SensorStatus.warning => 'Needs attention',
      SensorStatus.critical => 'Critical',
    };
