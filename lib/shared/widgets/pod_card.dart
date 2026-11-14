import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/shared/widgets/crop_photo.dart';
import 'package:aquagrow_mobile/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';

/// One pod on the My Pods screen, from the Figma component "PodCard": a
/// photo with a stage badge, then the crop name, where the pod is, the
/// growth stage and a harvest line.
///
/// ```dart
/// PodCard(
///   cropName: 'Genovese Basil',
///   location: 'Kitchen · Pod Alpha',
///   stageLabel: 'Growing',
///   harvestLine: 'Day 8 of 28, harvest in about 20 days',
///   imageAsset: 'assets/images/crops/basil.png',
///   onTap: () => context.push(AppRoutes.cropDetail(pod.id)),
/// )
/// ```
class PodCard extends StatelessWidget {
  /// Creates a pod card.
  const PodCard({
    required this.cropName,
    required this.location,
    required this.stageLabel,
    required this.harvestLine,
    this.imageAsset,
    this.onTap,
    super.key,
  });

  /// Height of the photo in the Figma design.
  static const double photoHeight = 180;

  /// Crop name, for example "Genovese Basil".
  final String cropName;

  /// Room and pod name, for example "Kitchen · Pod Alpha".
  final String location;

  /// Growth stage, for example "Growing". Shown in the photo badge and the body.
  final String stageLabel;

  /// Progress and harvest estimate, for example "Day 8 of 28, harvest in about 20 days".
  final String harvestLine;

  /// Bundled photo path. Null shows the plant placeholder.
  final String? imageAsset;

  /// Opens the pod. Null makes the card static and hides the chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: '$cropName. $location. $stageLabel. $harvestLine',
      button: onTap != null,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AgRadius.all(AgRadius.r32),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AgSpace.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: photoHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CropPhoto(
                          imageAsset: imageAsset,
                          radius: AgRadius.r24,
                        ),
                      ),
                      Positioned(
                        top: AgSpace.s12,
                        left: AgSpace.s12,
                        child: StatusBadge(label: stageLabel),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AgSpace.s12,
                    AgSpace.s12,
                    AgSpace.s12,
                    AgSpace.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cropName,
                              style: text.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: c.textSecondary,
                            ),
                        ],
                      ),
                      Text(
                        location,
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AgSpace.s12),
                      Text(stageLabel, style: text.labelLarge),
                      const SizedBox(height: AgSpace.s4),
                      Text(
                        harvestLine,
                        style:
                            text.bodyMedium?.copyWith(color: c.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
