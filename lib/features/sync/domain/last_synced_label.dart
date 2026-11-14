/// Short text for when the last sync happened, as in the Figma Profile row:
/// "Just now", "2 min ago", "3 h ago", "2 days ago", or "Not synced yet".
String lastSyncedLabel(DateTime? lastSyncedAt, {required DateTime now}) {
  if (lastSyncedAt == null) return 'Not synced yet';
  final age = now.difference(lastSyncedAt);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes} min ago';
  if (age.inDays < 1) return '${age.inHours} h ago';
  return age.inDays == 1 ? '1 day ago' : '${age.inDays} days ago';
}
