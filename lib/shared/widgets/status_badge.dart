import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Visual tone of a [StatusBadge].
enum BadgeTone { neutral, brand, warning, critical }

/// Pill-shaped label from Figma component "AquaGrow Refined/Badge".
///
/// ```dart
/// const StatusBadge(label: 'Live · 1m ago', tone: BadgeTone.brand)
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, this.tone = BadgeTone.neutral, super.key});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (c.surface, c.text),
      BadgeTone.brand => (c.brand, AgColors.light.text),
      BadgeTone.warning => (c.warningSurface, c.warning),
      BadgeTone.critical => (c.criticalSurface, c.critical),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AgSpace.s12, vertical: AgSpace.s4 + 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AgRadius.all(AgRadius.pill),
        border: tone == BadgeTone.neutral ? Border.all(color: c.border) : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
      ),
    );
  }
}
