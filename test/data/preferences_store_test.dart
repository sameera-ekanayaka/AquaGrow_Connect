import 'dart:io';

import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  void behavesLikeAPreferencesStore(IPreferencesStore Function() create) {
    test('returns the fallback when nothing is saved', () {
      final store = create();
      expect(store.getBool('missing'), isFalse);
      expect(store.getBool('missing', fallback: true), isTrue);
      expect(store.getString('missing'), isNull);
    });

    test('saves and reads flags and text', () async {
      final store = create();
      await store.setBool('asked', value: true);
      await store.setString('theme', 'dark');
      expect(store.getBool('asked'), isTrue);
      expect(store.getString('theme'), 'dark');
    });

    test('clear deletes everything', () async {
      final store = create();
      await store.setBool('asked', value: true);
      await store.clear();
      expect(store.getBool('asked'), isFalse);
    });
  }

  group('InMemoryPreferencesStore', () {
    behavesLikeAPreferencesStore(InMemoryPreferencesStore.new);
  });

  group('HivePreferencesStore', () {
    late Directory dir;
    late Box<dynamic> box;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('aquagrow_prefs_test');
      Hive.init(dir.path);
      box = await Hive.openBox<dynamic>('prefs_test');
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await dir.delete(recursive: true);
    });

    behavesLikeAPreferencesStore(() => HivePreferencesStore(box));
  });

  test('preferencesStoreProvider falls back to memory when Hive is not open',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(preferencesStoreProvider),
      isA<InMemoryPreferencesStore>(),
    );
  });
}
