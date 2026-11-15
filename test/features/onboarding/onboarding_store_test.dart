import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/onboarding/application/onboarding_store.dart';
import 'package:aquagrow_mobile/features/onboarding/domain/onboarding_slide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryPreferencesStore prefs;
  late OnboardingStore store;

  setUp(() {
    prefs = InMemoryPreferencesStore();
    store = OnboardingStore(prefs);
  });

  test('a fresh install has not seen onboarding', () {
    expect(store.isSeen, isFalse);
  });

  test('markSeen is remembered in app_preferences', () async {
    await store.markSeen();

    expect(store.isSeen, isTrue);
    expect(prefs.getBool(OnboardingStore.seenKey), isTrue);
  });

  test('deleting local data shows onboarding again', () async {
    await store.markSeen();
    await prefs.clear();

    expect(store.isSeen, isFalse);
  });

  test('there are three slides in the Figma order', () {
    expect(onboardingSlides.map((s) => s.title), [
      'Grow fresh food at home',
      'Know your plants live',
      "Get alerted before it's too late",
    ]);
  });
}
