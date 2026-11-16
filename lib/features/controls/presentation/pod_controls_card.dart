import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_control_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/controls/domain/dose_note.dart';
import 'package:aquagrow_mobile/features/controls/presentation/widgets/control_rows.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('controls');

/// The four commands on the card. Each can be busy on its own.
enum _Command { pump, light, brightness, dose }

/// "Pod controls" on Home, from the Figma frame "Home · Light": pump and
/// grow light switches, a brightness slider and a pH-down button.
///
/// Every command asks first ([showConfirmDialog]), then goes through
/// [controlRepositoryProvider]. (Who may use the app at all is decided by the
/// optional app lock in Settings, not per command.)
/// While a command runs, its control shows a spinner. An offline pod shows
/// why and disables everything.
///
/// ```dart
/// PodControlsCard(pod: pod)
/// ```
class PodControlsCard extends ConsumerStatefulWidget {
  /// Creates the controls for [pod].
  const PodControlsCard({required this.pod, super.key});

  /// The pod the commands go to.
  final Pod pod;

  @override
  ConsumerState<PodControlsCard> createState() => _PodControlsCardState();
}

class _PodControlsCardState extends ConsumerState<PodControlsCard> {
  final _busy = <_Command>{};

  /// Brightness while the finger is on the slider, before it is sent.
  double? _draftBrightness;

  /// Result of the last pH-down pulse sent from this card.
  PhDoseResult? _lastDose;

  Pod get _pod => widget.pod;

  @override
  void didUpdateWidget(PodControlsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod.id != _pod.id) {
      _busy.clear();
      _draftBrightness = null;
      _lastDose = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ag;

    return Material(
      color: c.surface,
      borderRadius: AgRadius.all(AgRadius.r24),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AgSpace.s8),
        child: _body(ref.watch(actuatorStateProvider(_pod.id))),
      ),
    );
  }

  Widget _body(AsyncValue<ActuatorState> actuators) {
    // In live mode, commands still go to the built-in simulator, which does
    // not know pods from Supabase, so they have no actuator state. That is
    // not the user's fault: explain it instead of "Something went wrong".
    if (actuators.hasError && !actuators.hasValue) {
      if (!_pod.isOnline) return _controls(ActuatorState.initial);
      return EmptyView(
        icon: Icons.tune_rounded,
        title: 'Controls not connected yet',
        message: 'Pump, light and pH controls for ${_pod.name} are not '
            'connected in live mode yet.',
      );
    }
    return AsyncValueView(
      value: actuators,
      onRetry: () => ref.invalidate(actuatorStateProvider(_pod.id)),
      data: _controls,
    );
  }

  Widget _controls(ActuatorState state) {
    final c = context.ag;
    final online = _pod.isOnline;
    final note = doseNoteFor(state, _lastDose);
    final noteColor = switch (note.tone) {
      DoseNoteTone.normal => null,
      DoseNoteTone.warning => c.warning,
      DoseNoteTone.critical => c.critical,
    };
    const offline = 'Pod is offline';

    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchRow(
          icon: Icons.cyclone_rounded,
          title: 'Water pump',
          subtitle: online ? (state.pumpOn ? 'Running' : 'Off') : offline,
          value: state.pumpOn,
          busy: _busy.contains(_Command.pump),
          onChanged: online ? (on) => _setPump(on: on) : null,
        ),
        SwitchRow(
          icon: Icons.lightbulb_rounded,
          title: 'Grow light',
          subtitle: online ? (state.lightOn ? 'On' : 'Off') : offline,
          value: state.lightOn,
          busy: _busy.contains(_Command.light),
          onChanged: online
              ? (on) => _setLight(on: on, brightness: state.lightBrightness)
              : null,
        ),
        SliderRow(
          icon: Icons.wb_sunny_rounded,
          title: 'Brightness',
          value: _draftBrightness ?? state.lightBrightness.toDouble(),
          busy: _busy.contains(_Command.brightness),
          onChanged: online && state.lightOn
              ? (v) => setState(() => _draftBrightness = v)
              : null,
          onChangeEnd: (v) => _setBrightness(v.round(), state),
        ),
        ActionRow(
          icon: Icons.science_rounded,
          title: 'pH down',
          note: online ? note.text : offline,
          noteColor: online ? noteColor : null,
          actionLabel: 'Dose',
          busy: _busy.contains(_Command.dose),
          onAction: online && !note.locked ? _dose : null,
        ),
      ],
    );

    if (online) return rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OfflineNote(podName: _pod.name),
        // Disabled controls fade to 38%, as in the Figma "Pod offline" frame.
        Opacity(opacity: 0.38, child: rows),
      ],
    );
  }

  Future<void> _setPump({required bool on}) => _send(
        _Command.pump,
        title: on ? 'Turn the pump on?' : 'Turn the pump off?',
        message: on
            ? 'Water starts flowing through ${_pod.name} again.'
            : 'Plants in ${_pod.name} will not get water until you turn it '
                'back on.',
        confirmLabel: on ? 'Turn on' : 'Turn off',
        destructive: !on,
        command: (repo) => repo.setPump(_pod.id, on: on),
      );

  Future<void> _setLight({required bool on, required int brightness}) => _send(
        _Command.light,
        title: on ? 'Turn the grow light on?' : 'Turn the grow light off?',
        message: on
            ? 'The light in ${_pod.name} comes on at $brightness%.'
            : 'Plants in ${_pod.name} get no light until you turn it back on.',
        confirmLabel: on ? 'Turn on' : 'Turn off',
        command: (repo) => repo.setLight(_pod.id, on: on),
      );

  Future<void> _setBrightness(int percent, ActuatorState state) async {
    if (percent == state.lightBrightness) {
      setState(() => _draftBrightness = null);
      return;
    }
    await _send(
      _Command.brightness,
      title: 'Set brightness to $percent%?',
      message: 'The grow light in ${_pod.name} changes right away.',
      confirmLabel: 'Set $percent%',
      command: (repo) => repo.setLight(_pod.id, on: true, brightness: percent),
    );
    // Show the pod's real value again, whether it was sent or cancelled.
    if (mounted) setState(() => _draftBrightness = null);
  }

  Future<void> _dose() => _send(
        _Command.dose,
        title: 'Add one pH-down pulse?',
        message: '${_pod.name} gets a small dose of pH-down. Wait a minute '
            'before dosing again.',
        confirmLabel: 'Dose',
        command: (repo) async {
          final result = await repo.dosePhDown(_pod.id);
          if (!mounted) return;
          setState(() => _lastDose = result);
          if (result == PhDoseResult.applied) _snack('pH lowered');
        },
      );

  /// Confirm, check the user, then run [command] with a spinner on [which].
  Future<void> _send(
    _Command which, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function(IControlRepository repo) command,
    bool destructive = false,
  }) async {
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!ok || !mounted) return;

    setState(() => _busy.add(which));
    try {
      await command(ref.read(controlRepositoryProvider));
    } on AppFailure catch (e) {
      _log.warning('${which.name} failed for ${_pod.id}', e);
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(which));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// "Controls come back when Pod Alpha reconnects." above disabled controls.
class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.podName});

  final String podName;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AgSpace.s16,
        AgSpace.s8,
        AgSpace.s16,
        AgSpace.s4,
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: AgSpace.s20, color: c.text),
          const SizedBox(width: AgSpace.s8),
          Expanded(
            child: Text(
              'Controls come back when $podName reconnects.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.text,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
