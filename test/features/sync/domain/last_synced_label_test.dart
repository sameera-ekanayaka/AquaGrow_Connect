import 'package:aquagrow_mobile/features/sync/domain/last_synced_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 10);

  test('says not synced yet when there was no sync', () {
    expect(lastSyncedLabel(null, now: now), 'Not synced yet');
  });

  test('says just now under a minute', () {
    expect(
      lastSyncedLabel(now.subtract(const Duration(seconds: 40)), now: now),
      'Just now',
    );
  });

  test('counts minutes, hours and days', () {
    expect(
      lastSyncedLabel(now.subtract(const Duration(minutes: 2)), now: now),
      '2 min ago',
    );
    expect(
      lastSyncedLabel(now.subtract(const Duration(hours: 3)), now: now),
      '3 h ago',
    );
    expect(
      lastSyncedLabel(now.subtract(const Duration(days: 1)), now: now),
      '1 day ago',
    );
    expect(
      lastSyncedLabel(now.subtract(const Duration(days: 4)), now: now),
      '4 days ago',
    );
  });
}
