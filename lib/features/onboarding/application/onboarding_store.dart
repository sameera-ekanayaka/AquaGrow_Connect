import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remembers whether the first-launch walkthrough was shown, in the Hive
/// `app_preferences` box.
///
/// The router reads [isSeen] to decide whether to open onboarding first.
/// "Delete my local data" in Settings clears the flag, so the walkthrough
/// shows again after that.
class OnboardingStore {
  /// Creates the store on top of [preferences].
  const OnboardingStore(this._preferences);

  /// Key in `app_preferences`.
  static const seenKey = 'onboarding_seen';

  final IPreferencesStore _preferences;

  /// True once the user finished or skipped the walkthrough.
  bool get isSeen => _preferences.getBool(seenKey);

  /// Records that the walkthrough was finished or skipped.
  Future<void> markSeen() => _preferences.setBool(seenKey, value: true);
}

/// The app's [OnboardingStore].
final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return OnboardingStore(ref.watch(preferencesStoreProvider));
});
