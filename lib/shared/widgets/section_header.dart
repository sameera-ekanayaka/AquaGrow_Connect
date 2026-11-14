import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Section title with an optional trailing action or caption,
/// for example "Growing conditions · Updated 1m ago" or "Your plants · View crops".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.caption,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;

  /// Quiet text on the right, such as "Updated 1m ago".
  final String? caption;

  /// Tappable text on the right, such as "View crops". Needs [onAction].
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: text.titleLarge)),
          if (caption != null) Text(caption!, style: text.bodySmall),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
