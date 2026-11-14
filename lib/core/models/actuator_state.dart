import 'package:flutter/foundation.dart';

/// What the pod's pump, grow light and pH doser are doing right now.
@immutable
class ActuatorState {
  const ActuatorState({
    required this.pumpOn,
    required this.lightOn,
    required this.lightBrightness,
    this.lastPhDoseAt,
    this.phDosesWithoutChange = 0,
  });

  static const initial = ActuatorState(pumpOn: true, lightOn: true, lightBrightness: 80);

  /// Max pH-down pulses in a row with no pH drop before dosing locks
  /// (safety lock, like the Bluelab dosers: a bottle may be empty or the pump broken).
  static const maxDosesWithoutChange = 5;

  /// Circulation pump.
  final bool pumpOn;

  /// LED grow light.
  final bool lightOn;

  /// 0 to 100 percent.
  final int lightBrightness;

  /// Time of the last pH-down pulse, or null.
  final DateTime? lastPhDoseAt;

  /// Pulses in a row that did not lower pH.
  final int phDosesWithoutChange;

  /// True when dosing is locked for safety.
  bool get dosingLocked => phDosesWithoutChange >= maxDosesWithoutChange;

  ActuatorState copyWith({
    bool? pumpOn,
    bool? lightOn,
    int? lightBrightness,
    DateTime? lastPhDoseAt,
    int? phDosesWithoutChange,
  }) {
    return ActuatorState(
      pumpOn: pumpOn ?? this.pumpOn,
      lightOn: lightOn ?? this.lightOn,
      lightBrightness: lightBrightness ?? this.lightBrightness,
      lastPhDoseAt: lastPhDoseAt ?? this.lastPhDoseAt,
      phDosesWithoutChange: phDosesWithoutChange ?? this.phDosesWithoutChange,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ActuatorState &&
      other.pumpOn == pumpOn &&
      other.lightOn == lightOn &&
      other.lightBrightness == lightBrightness &&
      other.lastPhDoseAt == lastPhDoseAt &&
      other.phDosesWithoutChange == phDosesWithoutChange;

  @override
  int get hashCode =>
      Object.hash(pumpOn, lightOn, lightBrightness, lastPhDoseAt, phDosesWithoutChange);
}
