import 'dart:math' as math;

import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/onboarding/domain/onboarding_slide.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Largest tint circle, as in Figma (320).
const double _maxVisual = 320;

/// The photo fills this share of the tint circle (256 of 320).
const double _photoShare = 0.8;

/// One onboarding page: a photo in a tinted circle, an optional badge over
/// it, then the heading and one sentence.
///
/// It scrolls when the screen is short (landscape, large text), so nothing
/// is cut off.
class SlideView extends StatelessWidget {
  /// Creates the page for [slide].
  const SlideView({required this.slide, super.key});

  /// What to show.
  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          _maxVisual,
          math.min(constraints.maxWidth * 0.9, constraints.maxHeight * 0.5),
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AgSpace.s24),
              Center(child: _Visual(slide: slide, size: size)),
              const SizedBox(height: AgSpace.s32),
              Text(
                slide.title,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AgSpace.s12),
              Text(
                slide.body,
                style: text.bodyLarge?.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The tinted circle, the round photo and the badge.
class _Visual extends StatelessWidget {
  const _Visual({required this.slide, required this.size});

  final OnboardingSlide slide;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final photo = size * _photoShare;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.brandSurface,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: size),
          ),
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: photo,
              child: CropPhoto(
                imageAsset: slide.imageAsset,
                radius: photo / 2,
              ),
            ),
          ),
          if (slide.badge == SlideBadge.sensorTile)
            Positioned(
              right: 0,
              bottom: 0,
              width: size * 0.47,
              child: const SensorTile(
                label: 'pH',
                value: '6.2',
                caption: 'Target 5.5-6.5',
              ),
            ),
          if (slide.badge == SlideBadge.alertRow)
            Positioned(
              left: size * 0.1,
              right: -AgSpace.s8,
              bottom: AgSpace.s8,
              child: const _AlertPreview(),
            ),
        ],
      ),
    );
  }
}

/// A sample "Water needs attention" alert, floating over slide 3.
class _AlertPreview extends StatelessWidget {
  const _AlertPreview();

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Material(
      color: c.surface,
      elevation: 6,
      shadowColor: c.text.withValues(alpha: 0.2),
      borderRadius: AgRadius.all(AgRadius.r20),
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s12),
        child: Row(
          children: [
            Container(
              width: AgSpace.s32,
              height: AgSpace.s32,
              decoration: BoxDecoration(
                color: c.warningSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: AgSpace.s16,
                color: c.warning,
              ),
            ),
            const SizedBox(width: AgSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Water needs attention',
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Refill Pod Alpha today.',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('Now', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
