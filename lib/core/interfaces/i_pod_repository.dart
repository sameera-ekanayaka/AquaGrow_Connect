import 'package:aquagrow_mobile/core/models/pod.dart';

/// Source of the user's pods.
///
/// Implementations:
/// - `SimPodRepository` (lib/data/simulation): the demo pods. Done.
/// - Supabase `devices` table: Sameera's task, see docs/tasks/sameera.md.
abstract interface class IPodRepository {
  /// Emits the current pods immediately, then again whenever any pod changes.
  Stream<List<Pod>> watchPods();

  /// One-off read of the current pods.
  Future<List<Pod>> getPods();
}
