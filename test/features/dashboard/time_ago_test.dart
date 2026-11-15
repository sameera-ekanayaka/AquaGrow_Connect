import 'package:aquagrow_mobile/features/dashboard/domain/time_ago.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats each range', () {
    expect(timeAgo(const Duration(seconds: 2)), 'just now');
    expect(timeAgo(const Duration(seconds: -3)), 'just now');
    expect(timeAgo(const Duration(seconds: 12)), '12s ago');
    expect(timeAgo(const Duration(minutes: 9, seconds: 40)), '9 min ago');
    expect(timeAgo(const Duration(hours: 3, minutes: 5)), '3 h ago');
    expect(timeAgo(const Duration(days: 2, hours: 1)), '2 d ago');
  });
}
