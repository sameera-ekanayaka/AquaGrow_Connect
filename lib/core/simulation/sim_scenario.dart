/// Situations the presenter can trigger from the simulator panel during the demo.
///
/// Each one pushes a pod into a state that shows off a feature:
/// colours change, an alert fires, a control fixes it.
enum SimScenario {
  normal(
    'Healthy pod',
    'All readings return to their healthy targets and the tank is refilled.',
  ),
  acidSpike(
    'pH crash',
    'pH drops to 4.8. Tiles turn red and a critical alert fires.',
  ),
  alkalineDrift(
    'pH too high',
    'pH climbs to 7.4. Use the pH-down doser to bring it back.',
  ),
  lowWater(
    'Low water',
    'Water level falls to 12%. A refill task appears on Home.',
  ),
  heatwave(
    'Heatwave',
    'Water warms to 29°C, which stresses roots.',
  ),
  nutrientDepletion(
    'Nutrients used up',
    'EC drops to 0.5 mS/cm. Plants need feeding.',
  ),
  doserEmpty(
    'pH bottle empty',
    'pH-down pulses stop working. After 5 tries the safety lock engages.',
  ),
  sensorOffline(
    'Pod offline',
    'The pod stops reporting, as if Wi-Fi dropped. Shows the offline state.',
  );

  const SimScenario(this.label, this.description);

  /// Button text on the simulator panel.
  final String label;

  /// One line explaining what the scenario demonstrates.
  final String description;
}

/// Outcome of a pH-down pulse.
enum PhDoseResult {
  /// pH went down.
  applied,

  /// The pulse ran but pH did not change (bottle empty or pump fault).
  noEffect,

  /// Too many pulses without effect. Dosing is locked until the scenario resets.
  locked,
}
