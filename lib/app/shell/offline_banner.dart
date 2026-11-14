import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the phone has no network connection (lecture 1: mobile networks).
///
/// Sameera's sync service also listens to this to upload queued data when
/// the connection returns.
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool offline(List<ConnectivityResult> r) =>
      r.isEmpty || r.every((c) => c == ConnectivityResult.none);

  yield offline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(offline);
});

/// Thin bar under the status bar while offline. The app keeps working on
/// cached and simulated data, so this only informs, it never blocks.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final c = context.ag;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: offline
          ? Material(
              color: c.warningSurface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AgSpace.screen,
                    vertical: AgSpace.s8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 18, color: c.warning),
                      const SizedBox(width: AgSpace.s8),
                      Expanded(
                        child: Text(
                          'Offline. Showing saved data. Changes sync when you reconnect.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
