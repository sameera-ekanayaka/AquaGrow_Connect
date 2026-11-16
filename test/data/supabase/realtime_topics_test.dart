import 'package:aquagrow_mobile/data/supabase/realtime_topics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every subscription to the same pod gets its own channel name', () {
    final names = {
      for (var i = 0; i < 3; i++) RealtimeTopics.unique('telemetry-pod-alpha'),
    };

    expect(names, hasLength(3), reason: 'Home, alerts and sync (issue #64)');
    expect(names.every((n) => n.startsWith('telemetry-pod-alpha-')), isTrue);
  });
}
