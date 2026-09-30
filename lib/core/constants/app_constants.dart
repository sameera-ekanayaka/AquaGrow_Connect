/// Global application constants, configuration keys, and system thresholds.
class AppConstants {
  AppConstants._();

  // Secure Storage Keys
  static const String secureAuthTokenKey = 'aquagrow_secure_auth_token';
  static const String secureRefreshTokenKey = 'aquagrow_secure_refresh_token';
  static const String secureUserRoleKey = 'aquagrow_user_role';

  // Hive Box Identifiers
  static const String telemetryOfflineCacheBoxKey = 'telemetry_offline_cache';
  static const String offlineQueueBoxKey = 'offline_sync_queue';
  static const String preferencesBoxKey = 'app_preferences';

  // Cache and Offline Synchronization Policy
  static const int telemetryRetentionHours = 72;
  static const int maxOfflineQueueItems = 500;
  static const int maxLocalTelemetryPoints = 500;

  // Default Hydroponic Threshold Windows
  static const double defaultMinPh = 5.5;
  static const double defaultMaxPh = 6.5;
  static const double defaultMinEc = 1.2;
  static const double defaultMaxEc = 2.4;
  static const double defaultMinWaterTempC = 18.0;
  static const double defaultMaxWaterTempC = 24.0;
  static const double defaultMinWaterLevelPct = 20.0;

  // Fallback Mock Device Credentials for Viva and Demo Evaluation
  static const String mockDeviceId = 'dev-aquagrow-001';
  static const String mockSerialNumber = 'AQG-2026-NFT-0841';
  static const String mockOwnerEmail = 'grower@aquagrow.io';
}
