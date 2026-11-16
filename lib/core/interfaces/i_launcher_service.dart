/// Contract for external app launch actions such as phone dialer and map navigation.
abstract interface class ILauncherService {
  /// Opens the device phone dialer with [phone] pre-filled.
  ///
  /// Returns `true` if the dialer launched successfully, or `false` if unsupported.
  Future<bool> dial(String phone);

  /// Opens turn-by-turn map directions to [latitude], [longitude] with an optional [label].
  ///
  /// Returns `true` if a maps application or web fallback launched, or `false` on failure.
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  });
}
