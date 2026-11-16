import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/insights/domain/readings_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readingsToCsv', () {
    test('returns header only when readings list is empty', () {
      final csv = readingsToCsv([]);
      expect(
        csv,
        'recorded_at,ph,ec_ms,tds_ppm,water_temp_c,ambient_temp_c,humidity_pct,water_level_pct\n',
      );
    });

    test('formats rows oldest first in UTC ISO 8601', () {
      final t1 = DateTime.utc(2026, 11, 15, 10, 0);
      final t2 = DateTime.utc(2026, 11, 15, 11, 0);

      final r1 = SensorReading(
        id: '1',
        deviceId: 'pod-alpha',
        ph: 6.2,
        tdsPpm: 800,
        ecMs: 1.6,
        waterTempC: 22.5,
        ambientTempC: 25.0,
        humidityPct: 70.0,
        waterLevelPct: 80,
        recordedAt: t2, // passed newest first
      );

      final r2 = SensorReading(
        id: '2',
        deviceId: 'pod-alpha',
        ph: 6.0,
        tdsPpm: 750,
        ecMs: 1.5,
        waterTempC: 22.0,
        ambientTempC: 24.5,
        humidityPct: 72.0,
        waterLevelPct: 82,
        recordedAt: t1,
      );

      final csv = readingsToCsv([r1, r2]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 3);
      expect(lines[0], contains('recorded_at,ph,ec_ms'));
      // Oldest row (t1) should be first data line
      expect(lines[1], startsWith('2026-11-15T10:00:00.000Z,6.0,1.5,750'));
      // Newer row (t2) should be second data line
      expect(lines[2], startsWith('2026-11-15T11:00:00.000Z,6.2,1.6,800'));
    });

    test('leaves empty cell for null optional values without personal data',
        () {
      final t = DateTime.utc(2026, 11, 15, 8, 30);
      final r = SensorReading(
        id: '3',
        deviceId: 'pod-beta',
        ph: 5.8,
        tdsPpm: 900,
        ecMs: 1.8,
        waterTempC: 21.0,
        ambientTempC: null,
        humidityPct: null,
        waterLevelPct: 60,
        recordedAt: t,
      );

      final csv = readingsToCsv([r]);
      expect(
        csv,
        contains('2026-11-15T08:30:00.000Z,5.8,1.8,900.0,21.0,,,60.0'),
      );
      // Confirms no user name, email, or coordinates exist in the output
      expect(csv, isNot(contains('pod-beta')));
      expect(csv, isNot(contains('grower')));
      expect(csv, isNot(contains('@')));
    });

    test('escapes special characters with RFC 4180 quotes', () {
      expect(escapeCsvCell('regular_text'), 'regular_text');
      expect(escapeCsvCell('text,with,commas'), '"text,with,commas"');
      expect(escapeCsvCell('text "with" quotes'), '"text ""with"" quotes"');
      expect(escapeCsvCell('line1\nline2'), '"line1\nline2"');
    });
  });

  group('buildCsvFileName', () {
    test('constructs standardized sanitized filename with slug and timestamp',
        () {
      final now = DateTime(2026, 11, 16, 14, 25);
      final fileName =
          buildCsvFileName(podName: 'Pod Alpha (Kitchen)', now: now);
      expect(fileName, 'aquagrow_pod_alpha_kitchen_20261116_1425.csv');
    });

    test('falls back to "pod" slug when name is whitespace or symbols', () {
      final now = DateTime(2026, 11, 16, 9, 5);
      final fileName = buildCsvFileName(podName: '   ***   ', now: now);
      expect(fileName, 'aquagrow_pod_20261116_0905.csv');
    });
  });
}
