import 'package:aquagrow_mobile/features/sync/application/sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the sync service running while [child] is shown, and says
/// "Back online · 37 readings synced" after queued readings are uploaded.
///
/// Wrap the signed-in part of the app (the shell) with it once. It only
/// listens, so it never rebuilds [child].
class SyncListener extends ConsumerWidget {
  /// Wraps [child].
  const SyncListener({required this.child, super.key});

  /// The part of the app that stays on screen while signed in.
  final Widget child;

  /// The SnackBar text for [count] uploaded readings.
  static String messageFor(int count) =>
      'Back online · $count ${count == 1 ? 'reading' : 'readings'} synced';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<int>>(syncedCountsProvider, (_, next) {
      final count = next.valueOrNull;
      if (count == null || count == 0) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(messageFor(count))));
    });
    return child;
  }
}
