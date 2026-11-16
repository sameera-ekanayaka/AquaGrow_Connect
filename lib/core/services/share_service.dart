import 'dart:typed_data';

import 'package:aquagrow_mobile/core/interfaces/i_share_service.dart';
import 'package:share_plus/share_plus.dart';

/// Concrete implementation of [IShareService] using the `share_plus` plugin.
class ShareService implements IShareService {
  /// Creates a share service.
  const ShareService();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  @override
  Future<void> shareBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? text,
  }) async {
    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      name: fileName,
      mimeType: mimeType,
    );
    await Share.shareXFiles([xFile], text: text);
  }
}
