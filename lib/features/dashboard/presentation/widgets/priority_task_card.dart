import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/dashboard/domain/priority_task.dart';
import 'package:flutter/material.dart';

/// The task card on Home from the Figma component "TaskCard": a tinted card
/// with an icon, the problem in words and, when there is one, a full-width
/// button that fixes it.
class PriorityTaskCard extends StatelessWidget {
  /// Creates the card for [task]. [onAction] runs the task's action.
  const PriorityTaskCard({required this.task, this.onAction, super.key});

  /// The problem to show.
  final PriorityTask task;

  /// Called when the button is tapped. The button is hidden when the task
  /// has no action, and disabled when this is null.
  final VoidCallback? onAction;

  /// Icon for each metric, matching the sensor tiles in Figma.
  static IconData iconFor(SensorMetric metric) => switch (metric) {
        SensorMetric.ph => Icons.science_rounded,
        SensorMetric.ec => Icons.bolt_rounded,
        SensorMetric.waterTemp => Icons.thermostat_rounded,
        SensorMetric.waterLevel => Icons.water_drop_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final critical = task.status == SensorStatus.critical;
    final tone = critical ? c.critical : c.warning;
    final label = task.actionLabel;

    return Container(
      padding: const EdgeInsets.all(AgSpace.s20),
      decoration: BoxDecoration(
        color: critical ? c.criticalSurface : c.warningSurface,
        borderRadius: AgRadius.all(AgRadius.r24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AgSpace.s32 + AgSpace.s8,
                height: AgSpace.s32 + AgSpace.s8,
                decoration: BoxDecoration(
                  color: c.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconFor(task.metric), color: tone),
              ),
              const SizedBox(width: AgSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        task.title,
                        style: text.titleMedium?.copyWith(color: tone),
                      ),
                    ),
                    const SizedBox(height: AgSpace.s4),
                    Text(task.message, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: AgSpace.s16),
            FilledButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
