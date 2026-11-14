import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// A rounded crop photo that fills its parent, used by [CropTile], [CropHero]
/// and [PodCard].
///
/// Without an [imageAsset], or if the asset cannot be loaded, it shows a quiet
/// placeholder: a `subtle` box with a plant icon in a circle.
///
/// ```dart
/// const CropPhoto(imageAsset: 'assets/images/crops/basil.png', radius: AgRadius.r24)
/// ```
class CropPhoto extends StatelessWidget {
  /// Creates a crop photo with corner [radius].
  const CropPhoto({required this.radius, this.imageAsset, super.key});

  /// Bundled photo path, for example `assets/images/crops/basil.png`.
  final String? imageAsset;

  /// Corner radius, one of the [AgRadius] values.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset;
    return ClipRRect(
      borderRadius: AgRadius.all(radius),
      child: asset == null
          ? const CropPhotoPlaceholder()
          : Image.asset(
              asset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) =>
                  const CropPhotoPlaceholder(),
            ),
    );
  }
}

/// The empty state of a [CropPhoto]: a `subtle` box with a 48 px circle and
/// a plant icon, from the Figma "Image=Placeholder" variants.
class CropPhotoPlaceholder extends StatelessWidget {
  /// Creates the placeholder.
  const CropPhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return ColoredBox(
      color: c.subtle,
      child: Center(
        child: Container(
          width: kMinTouchTarget,
          height: kMinTouchTarget,
          decoration:
              BoxDecoration(color: c.background, shape: BoxShape.circle),
          child: Icon(
            Icons.grass_rounded,
            color: c.textSecondary,
            semanticLabel: 'No photo',
          ),
        ),
      ),
    );
  }
}
