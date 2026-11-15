/// Deletes everything the app keeps on this phone, for the privacy note's
/// "Delete my local data" button.
///
/// Implementation: `HiveLocalDataEraser` (lib/data/local). It never touches
/// the user's account or cloud data.
abstract interface class ILocalDataEraser {
  /// Clears saved readings, the upload queue and app preferences.
  Future<void> eraseAll();
}
