import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/shared/widgets/crop_photo.dart';
import 'package:flutter/material.dart';

/// Small crop card from the Figma component "CropTile": a rounded photo with
/// the crop name and one detail line underneath. Used for "Your plants" on Home.
///
/// ```dart
/// const CropTile(
///   title: 'Baby Spinach',
///   detail: 'Dining room, day 4',
///   imageAsset: 'assets/images/crops/spinach.png',
/// )
/// ```
class CropTile extends StatelessWidget {
  /// Creates a crop tile.
  const CropTile({
    required this.title,
    required this.detail,
    this.imageAsset,
    this.onTap,
    this.width = tileWidth,
    super.key,
  });

  /// Width of the tile in the Figma design.
  static const double tileWidth = 166;

  /// Height of the photo in the Figma design.
  static const double photoHeight = 140;

  /// Crop name, for example "Baby Spinach".
  final String title;

  /// One short line under the name, for example "Dining room, day 4".
  final String detail;

  /// Bundled photo path. Null shows the plant placeholder.
  final String? imageAsset;

  /// Called when the tile is tapped. Null makes the tile static.
  final VoidCallback? onTap;

  /// Tile width. Defaults to [tileWidth]; pass `double.infinity` to fill a grid cell.
  final double width;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: '$title. $detail',
      button: onTap != null,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: InkWell(
          onTap: onTap,
          borderRadius: AgRadius.all(AgRadius.r24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: photoHeight,
                width: double.infinity,
                child: CropPhoto(imageAsset: imageAsset, radius: AgRadius.r24),
              ),
              const SizedBox(height: AgSpace.s12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AgSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      detail,
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
