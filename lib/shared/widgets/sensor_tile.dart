import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

export 'package:aquagrow_mobile/core/models/sensor_status.dart';

/// One reading card from the Minimal UI "Sensor" component: an optional
/// icon in a circle, a label, a big value and a context line such as the
/// target range. Filled with the surface colour; a critical reading gets a
/// red outline.
///
/// ```dart
/// SensorTile(label: 'pH', value: '6.2', caption: 'Target 5.5–6.5')
/// ```
class SensorTile extends StatelessWidget {
  const SensorTile({
    required this.label,
    required this.value,
    required this.caption,
    this.status = SensorStatus.normal,
    this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String caption;
  final SensorStatus status;

  /// Metric icon shown in a circle above the label, or none.
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final valueColor = switch (status) {
      SensorStatus.normal => c.text,
      SensorStatus.warning => c.warning,
      SensorStatus.critical => c.critical,
    };

    return Semantics(
      label: '$label $value. $caption',
      button: onTap != null,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AgRadius.all(AgRadius.r20),
          side: status == SensorStatus.critical
              ? BorderSide(color: c.critical)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AgSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  _IconCircle(icon: icon!, status: status),
                  const Spacer(),
                ],
                Text(label, style: text.bodySmall),
                const SizedBox(height: AgSpace.s8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.displaySmall?.copyWith(color: valueColor),
                  ),
                ),
                const SizedBox(height: AgSpace.s8),
                Text(caption, style: text.bodySmall, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White circle holding the metric icon; tinted when the reading is off.
class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.status});

  final IconData icon;
  final SensorStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final (fill, tint) = switch (status) {
      SensorStatus.normal => (c.background, c.text),
      SensorStatus.warning => (c.warningSurface, c.warning),
      SensorStatus.critical => (c.criticalSurface, c.critical),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}
