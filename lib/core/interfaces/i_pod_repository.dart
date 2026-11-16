import 'package:aquagrow_mobile/core/models/crop_recipe.dart';
import 'package:aquagrow_mobile/core/models/new_pod.dart';
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

  /// Adds [pod] for the signed-in user and returns it, with no crop yet.
  ///
  /// Throws a `ValidationFailure` if the serial number is already
  /// registered, or another `AppFailure` (network, sign-in) if it fails.
  Future<Pod> addPod(NewPod pod);

  /// Starts growing [recipe] in the empty pod [podId], planted today.
  ///
  /// Throws a `ValidationFailure` if the pod already grows a crop, or another
  /// `AppFailure` (network, sign-in) if it fails.
  Future<void> plantCrop(String podId, CropRecipe recipe);

  /// Marks the crop in [podId] as harvested, so the pod is empty again.
  Future<void> harvest(String podId);

  /// Deletes pod [podId] with its crops and readings. Cannot be undone.
  Future<void> deletePod(String podId);
}
