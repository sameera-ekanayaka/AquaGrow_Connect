import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks before deleting [pod], deletes it and shows the outcome.
///
/// Returns true when the pod was deleted, so the caller can close its screen.
Future<bool> confirmDeletePod(
  BuildContext context,
  WidgetRef ref,
  Pod pod,
) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Delete ${pod.name}?',
    message: 'Its crop and readings are deleted too. This cannot be undone.',
    confirmLabel: 'Delete pod',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(podRepositoryProvider).deletePod(pod.id);
  } on AppFailure catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
  messenger.showSnackBar(SnackBar(content: Text('${pod.name} deleted')));
  return true;
}
