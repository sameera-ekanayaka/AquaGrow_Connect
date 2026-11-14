import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';

export 'package:aquagrow_mobile/core/simulation/sim_scenario.dart' show PhDoseResult;

/// Commands sent to a pod's pump, grow light and pH doser.
///
/// RULE: the UI must show a confirm dialog before calling any method here
/// (see `showConfirmDialog`). Methods throw `DeviceFailure` when the pod is
/// offline or does not acknowledge.
///
/// Implementations:
/// - `SimControlRepository` (lib/data/simulation): drives the simulator. Done.
/// - Supabase `device_commands` table: Sameera's task (stretch).
abstract interface class IControlRepository {
  /// Emits the current state immediately, then on every change.
  Stream<ActuatorState> watchActuators(String podId);

  /// Turns the circulation pump on or off.
  Future<void> setPump(String podId, {required bool on});

  /// Turns the grow light on or off, optionally setting brightness (0 to 100).
  Future<void> setLight(String podId, {required bool on, int? brightness});

  /// Runs one pH-down pulse. Check the result: it can be locked for safety.
  Future<PhDoseResult> dosePhDown(String podId);

  /// Records that the user refilled the reservoir.
  Future<void> markRefilled(String podId);
}
