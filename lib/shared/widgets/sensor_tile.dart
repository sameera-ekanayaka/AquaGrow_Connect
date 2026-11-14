import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

export 'package:aquagrow_mobile/core/models/sensor_status.dart';

/// One reading card from Figma component "AquaGrow Refined/Sensor":
/// a label, a big value and a context line such as the target range.
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
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String caption;
  final SensorStatus status;
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
          side: BorderSide(
            color: status == SensorStatus.critical ? c.critical : c.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AgSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
