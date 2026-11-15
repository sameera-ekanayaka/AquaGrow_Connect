import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';

/// How loudly a [DoseNote] should be shown.
enum DoseNoteTone {
  /// Plain helper text.
  normal,

  /// The last pulse did nothing. Shown in the warning colour.
  warning,

  /// Dosing is locked. Shown in the critical colour, and the button is off.
  critical,
}

/// The line under "pH down" on the controls card.
class DoseNote {
  /// Creates a note with [text] at [tone].
  const DoseNote(this.text, this.tone);

  /// What the user reads.
  final String text;

  /// How it is coloured.
  final DoseNoteTone tone;

  /// True when the Dose button must be disabled.
  bool get locked => tone == DoseNoteTone.critical;

  @override
  bool operator ==(Object other) =>
      other is DoseNote && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(text, tone);
}

/// Picks the pH-down note from the doser's [state] and the [lastResult] of
/// the user's most recent pulse in this session (null if none yet).
///
/// The lock in [state] always wins, so a lock that happened elsewhere (for
/// example from the simulator panel) still shows.
DoseNote doseNoteFor(ActuatorState state, PhDoseResult? lastResult) {
  if (state.dosingLocked || lastResult == PhDoseResult.locked) {
    return const DoseNote('Dosing locked for safety', DoseNoteTone.critical);
  }
  if (lastResult == PhDoseResult.noEffect && state.phDosesWithoutChange > 0) {
    return DoseNote(
      'No change. Check the pH-down bottle '
      '(${state.phDosesWithoutChange} of ${ActuatorState.maxDosesWithoutChange}).',
      DoseNoteTone.warning,
    );
  }
  return const DoseNote(
    'Adds one small pulse of pH-down',
    DoseNoteTone.normal,
  );
}
