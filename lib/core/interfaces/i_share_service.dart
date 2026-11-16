/// Contract for sharing text and binary export data via platform share sheets.
abstract interface class IShareService {
  /// Opens the system share sheet with the provided [text] and optional [subject].
  Future<void> shareText(String text, {String? subject});

  /// Shares binary [bytes] as a named file with [fileName] and [mimeType].
  Future<void> shareBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? text,
  });
}
