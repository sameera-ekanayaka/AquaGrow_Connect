import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Widest the sign-in and register forms grow on tablets and in landscape.
const double kAuthFormMaxWidth = 440;

/// The page frame shared by the sign-in and register screens: safe area,
/// screen padding, scrolling when the keyboard is open, and a form that
/// stays readable on wide screens.
class AuthPage extends StatelessWidget {
  /// Creates an auth page that stacks [children] top to bottom.
  const AuthPage({required this.children, this.appBar, super.key});

  /// Top-to-bottom content of the page.
  final List<Widget> children;

  /// Optional app bar, for example the back arrow on Create account.
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AgSpace.screen),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kAuthFormMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The AquaGrow mark from Figma: a lime circle with a leaf.
class AuthLogo extends StatelessWidget {
  /// Creates the logo, left-aligned unless [alignment] says otherwise.
  const AuthLogo({this.alignment = Alignment.centerLeft, super.key});

  /// Where the logo sits in the available width.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Align(
      alignment: alignment,
      child: Container(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
        // Lime stays light in both themes, so the leaf is always dark.
        child: Icon(
          Icons.eco_rounded,
          color: AgColors.light.text,
          semanticLabel: 'AquaGrow',
        ),
      ),
    );
  }
}

/// A screen title with one line of explanation under it.
class AuthHeader extends StatelessWidget {
  /// Creates a header such as "Welcome back".
  const AuthHeader({required this.title, required this.subtitle, super.key});

  /// Large title, for example "Welcome back".
  final String title;

  /// One quiet line under the title.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: text.headlineMedium),
        ),
        const SizedBox(height: AgSpace.s4),
        Text(
          subtitle,
          style: text.bodyMedium?.copyWith(color: context.ag.textSecondary),
        ),
      ],
    );
  }
}

/// A small label shown above a form field, as in Figma.
class FieldLabel extends StatelessWidget {
  /// Creates a label with [text].
  const FieldLabel(this.text, {super.key});

  /// Label text, for example "Email".
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

/// A red notice for a failed sign-in or registration.
///
/// Uses an icon and text as well as colour, so it is not colour-only.
class AuthErrorBanner extends StatelessWidget {
  /// Creates a banner showing [message].
  const AuthErrorBanner(this.message, {super.key});

  /// The friendly failure message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AgSpace.s12),
        decoration: BoxDecoration(
          color: c.criticalSurface,
          borderRadius: AgRadius.all(AgRadius.r16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: c.critical),
            const SizedBox(width: AgSpace.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: c.critical),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small spinner for inside a filled button while a request runs.
class ButtonSpinner extends StatelessWidget {
  /// Creates the spinner.
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AgSpace.s20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.ag.onDark,
      ),
    );
  }
}
