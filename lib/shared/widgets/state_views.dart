import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every list, chart and data screen must handle four states:
/// loading, error, empty and data. These widgets make that one line of code.
///
/// ```dart
/// AsyncValueView(
///   value: ref.watch(podsProvider),
///   isEmpty: (pods) => pods.isEmpty,
///   empty: const EmptyView(title: 'No pods yet', message: 'Add your first pod.'),
///   data: (pods) => PodList(pods: pods),
/// )
/// ```
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) => (isEmpty?.call(d) ?? false) && empty != null ? empty! : data(d),
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: error is AppFailure ? error.message : const UnexpectedFailure().message,
        onRetry: onRetry,
      ),
    );
  }
}

/// Centered progress indicator.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AgSpace.s24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Friendly error message with an optional retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.error_outline,
      iconColor: context.ag.critical,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

/// Shown when a list has no items yet.
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: icon,
      iconColor: context.ag.textSecondary,
      title: title,
      message: message,
      action: action,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: AgSpace.s12),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AgSpace.s8),
            Text(message, style: text.bodySmall, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AgSpace.s16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
