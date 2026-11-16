import 'dart:io';

import 'package:aquagrow_mobile/data/supabase/supabase_rows.dart';
import 'package:aquagrow_mobile/features/crops/domain/crop_recipes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseRows.pod', () {
    test('maps a device with its active crop batch', () {
      final pod = SupabaseRows.pod({
        'id': 'd1',
        'device_name': 'Pod Alpha',
        'room': 'Kitchen',
        'is_online': true,
        'last_seen_at': '2026-11-15T10:00:00Z',
        'crop_batches': [
          {
            'id': 'old',
            'status': 'HARVESTED',
            'planted_date': '2026-09-01',
            'crop_recipes': {'crop_name': 'Pak Choi', 'duration_days': 32},
          },
          {
            'id': 'b1',
            'status': 'ACTIVE',
            'custom_crop_name': null,
            'planted_date': '2026-11-08',
            'crop_recipes': {
              'crop_name': 'Italian Basil',
              'variety': 'Genovese',
              'duration_days': 28,
            },
          },
        ],
      });

      expect(pod.displayName, 'Pod Alpha · Kitchen');
      expect(pod.isOnline, isTrue);
      expect(pod.batch!.id, 'b1');
      expect(pod.batch!.cropName, 'Italian Basil');
      expect(pod.batch!.variety, 'Genovese');
      expect(pod.batch!.daysToHarvest, 28);
      expect(pod.batch!.imageAsset, 'assets/images/crops/basil-plants.webp');
      expect(pod.batch!.plantedAt, DateTime(2026, 11, 8));
    });

    test('prefers a custom crop name over the recipe name', () {
      final pod = SupabaseRows.pod({
        'id': 'd2',
        'device_name': 'Pod Beta',
        'crop_batches': [
          {
            'id': 'b2',
            'status': 'ACTIVE',
            'custom_crop_name': 'Baby Spinach',
            'planted_date': '2026-11-11',
            'crop_recipes': null,
          },
        ],
      });

      expect(pod.batch!.cropName, 'Baby Spinach');
      expect(pod.batch!.imageAsset, 'assets/images/crops/spinach.png');
      expect(pod.batch!.daysToHarvest, 30, reason: 'default without recipe');
    });

    test('a device with no active batch has no crop, and safe defaults', () {
      final pod = SupabaseRows.pod({'id': 'd3', 'crop_batches': []});

      expect(pod.batch, isNull);
      expect(pod.name, 'AquaGrow pod');
      expect(pod.room, 'Home');
      expect(pod.isOnline, isFalse);
    });
  });

  group('SupabaseRows.reading', () {
    test('maps numeric columns, including Postgres numerics sent as ints', () {
      final r = SupabaseRows.reading({
        'id': 42,
        'reading_id': 'pod-alpha-t7-1',
        'device_id': 'd1',
        'ph': 6.2,
        'tds_ppm': 820,
        'ec_ms': 1.64,
        'water_temp_c': 21,
        'ambient_temp_c': null,
        'humidity_pct': 55.5,
        'water_level_pct': 78,
        'recorded_at': '2026-11-15T10:00:00+00:00',
      });

      expect(r.id, 'pod-alpha-t7-1');
      expect(r.deviceId, 'd1');
      expect(r.tdsPpm, 820.0);
      expect(r.waterTempC, 21.0);
      expect(r.ambientTempC, isNull);
      expect(r.humidityPct, 55.5);
      expect(r.recordedAt.toUtc(), DateTime.utc(2026, 11, 15, 10));
    });

    test('falls back to the server id when there is no reading id', () {
      final r = SupabaseRows.reading({
        'id': 7,
        'device_id': 'd1',
        'ph': 6,
        'tds_ppm': 800,
        'ec_ms': 1.6,
        'water_temp_c': 21,
        'water_level_pct': 80,
        'recorded_at': '2026-11-15T10:00:00Z',
      });

      expect(r.id, '7');
    });
  });

  test('cropImage matches bundled photos and leaves others empty', () {
    expect(SupabaseRows.cropImage('Genovese Basil'), contains('basil'));
    expect(SupabaseRows.cropImage('Pak Choi'), contains('pak-choi'));
    expect(SupabaseRows.cropImage('Tomato'), isNull);
  });

  test('every recipe has a photo that is bundled with the app', () {
    for (final recipe in CropRecipes.all) {
      final asset = SupabaseRows.cropImage(recipe.cropName);
      expect(asset, isNotNull, reason: recipe.cropName);
      expect(File(asset!).existsSync(), isTrue, reason: asset);
    }
  });
}
