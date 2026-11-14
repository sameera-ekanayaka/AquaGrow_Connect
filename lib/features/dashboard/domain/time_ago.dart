/// Short, friendly age of a reading, for example "12s ago" or "9 min ago".
///
/// Under 5 seconds (or a clock that runs slightly behind) reads "just now".
String timeAgo(Duration elapsed) {
  if (elapsed.inSeconds < 5) return 'just now';
  if (elapsed.inMinutes < 1) return '${elapsed.inSeconds}s ago';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours} h ago';
  return '${elapsed.inDays} d ago';
}
