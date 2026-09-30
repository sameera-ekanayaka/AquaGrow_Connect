import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Service managing hardware-backed encrypted storage for tokens and credentials.
/// Utilizes Android Keystore (EncryptedSharedPreferences) and iOS Keychain.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Securely stores the primary JWT session access token.
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConstants.secureAuthTokenKey, value: token);
  }

  /// Retrieves the persisted JWT session access token.
  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.secureAuthTokenKey);
  }

  /// Securely stores the long-lived refresh token for silent session renewal.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.secureRefreshTokenKey, value: token);
  }

  /// Retrieves the persisted session refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.secureRefreshTokenKey);
  }

  /// Stores the authenticated user role to allow fast cold-start permission checks.
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: AppConstants.secureUserRoleKey, value: role);
  }

  /// Retrieves the cached user role.
  Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.secureUserRoleKey);
  }

  /// Deletes all session authentication tokens upon user sign-out.
  Future<void> clearAuthTokens() async {
    await _storage.delete(key: AppConstants.secureAuthTokenKey);
    await _storage.delete(key: AppConstants.secureRefreshTokenKey);
    await _storage.delete(key: AppConstants.secureUserRoleKey);
  }

  /// Generic write method for additional encrypted metadata.
  Future<void> writeCustomKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Generic read method for additional encrypted metadata.
  Future<String?> readCustomKey(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes an arbitrary encrypted key.
  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }
}
