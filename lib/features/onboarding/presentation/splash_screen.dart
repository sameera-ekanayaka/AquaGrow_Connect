import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Size of the round logo mark in Figma (88).
const double _logoSize = AgSpace.s32 * 2 + AgSpace.s24;

/// Size of the leaf inside the logo mark (44).
const double _leafSize = AgSpace.s32 + AgSpace.s12;

/// Figma "Splash": the lime logo mark with the AquaGrow Connect wordmark,
/// centred on the background.
///
/// Show it while the app restores the sign-in session, before the first
/// screen is ready.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Semantics(
          label: 'AquaGrow Connect',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _logoSize,
                height: _logoSize,
                decoration:
                    BoxDecoration(color: c.brand, shape: BoxShape.circle),
                // Lime stays light in both themes, so the leaf stays dark.
                child: Icon(
                  Icons.eco_rounded,
                  size: _leafSize,
                  color: AgColors.light.text,
                ),
              ),
              const SizedBox(height: AgSpace.s16),
              Text('AquaGrow', style: text.headlineMedium),
              Text(
                'Connect',
                style: text.bodyLarge?.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
