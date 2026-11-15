import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';
import 'package:aquagrow_mobile/features/controls/domain/dose_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fresh = ActuatorState.initial;

  test('shows the helper text before any dose', () {
    final note = doseNoteFor(fresh, null);

    expect(note.text, 'Adds one small pulse of pH-down');
    expect(note.tone, DoseNoteTone.normal);
    expect(note.locked, isFalse);
  });

  test('a dose that worked goes back to the helper text', () {
    expect(doseNoteFor(fresh, PhDoseResult.applied).tone, DoseNoteTone.normal);
  });

  test('no effect warns with the count of pulses so far', () {
    final note = doseNoteFor(
      fresh.copyWith(phDosesWithoutChange: 2),
      PhDoseResult.noEffect,
    );

    expect(note.text, 'No change. Check the pH-down bottle (2 of 5).');
    expect(note.tone, DoseNoteTone.warning);
  });

  test('a lock from the doser state wins over any result', () {
    final note = doseNoteFor(
      fresh.copyWith(phDosesWithoutChange: ActuatorState.maxDosesWithoutChange),
      null,
    );

    expect(note.text, 'Dosing locked for safety');
    expect(note.locked, isTrue);
  });

  test('a locked result is shown as locked', () {
    expect(doseNoteFor(fresh, PhDoseResult.locked).locked, isTrue);
  });

  test('a reset doser clears an old no-effect warning', () {
    // The scenario was reset, so the count went back to zero.
    expect(
      doseNoteFor(fresh, PhDoseResult.noEffect).tone,
      DoseNoteTone.normal,
    );
  });
}
