import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Size of the round icon at the start of every control row.
const double _iconCircle = AgSpace.s32 + AgSpace.s8;

/// Size of the progress ring shown while a command is running.
const double _busyRing = AgSpace.s24;

/// Minimum height of a switch row in Figma (72).
const double _rowHeight = AgSpace.s32 * 2 + AgSpace.s8;

/// Slider track thickness in Figma.
const double _trackHeight = AgSpace.s4 + 2;

/// The 40 px round icon at the start of a control row.
class ControlIcon extends StatelessWidget {
  /// Creates the icon circle for [icon].
  const ControlIcon(this.icon, {super.key});

  /// Material rounded icon, for example `Icons.cyclone_rounded`.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Container(
      width: _iconCircle,
      height: _iconCircle,
      decoration: BoxDecoration(color: c.background, shape: BoxShape.circle),
      child: Icon(icon, color: c.text, size: AgSpace.s20),
    );
  }
}

/// Small spinner shown in place of a control while its command runs.
class ControlBusy extends StatelessWidget {
  /// Creates the 24 px progress ring.
  const ControlBusy({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: _busyRing,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}

/// Figma "SwitchRow": icon, title, state in words and a switch.
///
/// Tapping anywhere on the row flips the switch. While [busy] the switch is
/// replaced by a progress ring and taps are ignored.
class SwitchRow extends StatelessWidget {
  /// Creates a switch row.
  const SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.busy = false,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// For example "Water pump".
  final String title;

  /// State in words, for example "Running" or "Pod is offline".
  final String subtitle;

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value. Null disables the row.
  final ValueChanged<bool>? onChanged;

  /// True while the command is being sent.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final change = busy ? null : onChanged;

    return MergeSemantics(
      child: InkWell(
        onTap: change == null ? null : () => change(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _rowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AgSpace.s16,
              vertical: AgSpace.s12,
            ),
            child: Row(
              children: [
                ControlIcon(icon),
                const SizedBox(width: AgSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      Text(subtitle, style: text.bodySmall),
                    ],
                  ),
                ),
                if (busy)
                  const ControlBusy()
                else
                  Switch(value: value, onChanged: change),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "SliderRow": icon, title and value, then a slider that only sends
/// when the finger lifts ([onChangeEnd]).
class SliderRow extends StatelessWidget {
  /// Creates a 0 to 100 percent slider row.
  const SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.busy = false,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// For example "Brightness".
  final String title;

  /// Current value, 0 to 100.
  final double value;

  /// Moves the thumb while dragging. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Sends the value when the drag ends.
  final ValueChanged<double>? onChangeEnd;

  /// True while the command is being sent.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final enabled = !busy && onChanged != null;
    final percent = '${value.round()}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AgSpace.s16,
        AgSpace.s12,
        AgSpace.s16,
        AgSpace.s4,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ControlIcon(icon),
              const SizedBox(width: AgSpace.s12),
              Expanded(child: Text(title, style: text.titleMedium)),
              if (busy)
                const ControlBusy()
              else
                Text(percent, style: text.titleMedium),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: _trackHeight,
              activeTrackColor: c.brand,
              inactiveTrackColor: c.subtle,
              thumbColor: c.background,
              overlayColor: c.brand.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.clamp(0, 100),
              max: 100,
              divisions: 20,
              label: percent,
              semanticFormatterCallback: (v) => '$title ${v.round()} percent',
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma "ActionRow": icon, title, a note and a small secondary button.
class ActionRow extends StatelessWidget {
  /// Creates an action row.
  const ActionRow({
    required this.icon,
    required this.title,
    required this.note,
    required this.actionLabel,
    required this.onAction,
    this.noteColor,
    this.busy = false,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// For example "pH down".
  final String title;

  /// The line under the title.
  final String note;

  /// Colour for [note]; null uses the secondary text colour.
  final Color? noteColor;

  /// Button text, for example "Dose".
  final String actionLabel;

  /// Runs the action. Null disables the button.
  final VoidCallback? onAction;

  /// True while the command is being sent.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AgSpace.s16,
        vertical: AgSpace.s12,
      ),
      child: Row(
        children: [
          ControlIcon(icon),
          const SizedBox(width: AgSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(
                  note,
                  style: text.bodySmall?.copyWith(color: noteColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AgSpace.s8),
          if (busy)
            const ControlBusy()
          else
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                backgroundColor: c.background,
                foregroundColor: c.text,
                side: BorderSide(color: c.border),
                shape: const StadiumBorder(),
                minimumSize: const Size(0, kMinTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: AgSpace.s20),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
