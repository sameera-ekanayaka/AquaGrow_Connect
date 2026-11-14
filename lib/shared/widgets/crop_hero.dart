import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/shared/widgets/crop_photo.dart';
import 'package:aquagrow_mobile/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';

/// Large crop card from the Figma component "CropHero": a full photo with a
/// stage badge in the top-left corner and a floating summary card at the
/// bottom holding the crop name, a caption and an open button.
///
/// ```dart
/// CropHero(
///   name: 'Genovese Basil',
///   badgeLabel: 'Day 8 · Growing',
///   caption: 'Harvest in about 20 days',
///   imageAsset: 'assets/images/crops/basil.png',
///   onTap: () => context.go(AppRoutes.crops),
/// )
/// ```
class CropHero extends StatelessWidget {
  /// Creates a crop hero card.
  const CropHero({
    required this.name,
    required this.badgeLabel,
    required this.caption,
    this.imageAsset,
    this.onTap,
    super.key,
  });

  /// Height of the card in the Figma design.
  static const double heroHeight = 300;

  /// Crop name, for example "Genovese Basil".
  final String name;

  /// Short status shown in the badge, for example "Day 8 · Growing".
  final String badgeLabel;

  /// One line under the name, for example "Harvest in about 20 days".
  final String caption;

  /// Bundled photo path. Null shows the plant placeholder.
  final String? imageAsset;

  /// Opens the crop. Null hides the open button and makes the card static.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final tap = onTap;

    return Semantics(
      label: '$name. $badgeLabel. $caption',
      button: tap != null,
      excludeSemantics: true,
      child: SizedBox(
        height: heroHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CropPhoto(imageAsset: imageAsset, radius: AgRadius.r32),
            ),
            Positioned(
              top: AgSpace.s12,
              left: AgSpace.s12,
              child: StatusBadge(label: badgeLabel),
            ),
            Positioned(
              left: AgSpace.s12,
              right: AgSpace.s12,
              bottom: AgSpace.s12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: AgRadius.all(AgRadius.r24),
                  boxShadow: [
                    BoxShadow(
                      color: AgColors.light.text.withValues(alpha: 0.06),
                      offset: const Offset(0, 6),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AgSpace.s16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: text.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AgSpace.s4),
                            Text(
                              caption,
                              style: text.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (tap != null) ...[
                        const SizedBox(width: AgSpace.s12),
                        IconButton.filled(
                          onPressed: tap,
                          tooltip: 'Open $name',
                          style: IconButton.styleFrom(
                            backgroundColor: c.brand,
                            // Lime keeps dark text in both themes, as in StatusBadge.
                            foregroundColor: AgColors.light.text,
                            minimumSize: const Size.square(kMinTouchTarget),
                          ),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
