/// Gives every realtime subscription its own channel name.
///
/// In `realtime_client`, subscribing a channel leaves any other joined
/// channel with the same topic, silently. Home, the alert engine and the
/// sync service all listen to the same pod, so with one shared name only the
/// last one to join received new readings (issue #64). The `device_id`
/// filter is unchanged, so every listener still gets every insert.
abstract final class RealtimeTopics {
  static int _next = 0;

  /// A channel name starting with [base] that no other subscription uses,
  /// for example `telemetry-pod-alpha-3`.
  static String unique(String base) => '$base-${_next++}';
}
