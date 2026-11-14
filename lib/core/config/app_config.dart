/// How the app gets its pod data.
enum DataMode {
  /// Readings come from the built-in pod simulator. No network or hardware
  /// needed. This is the default and what we use in the demo.
  simulation,

  /// Readings and accounts come from Supabase.
  live,
}

/// Build-time configuration, read from `--dart-define` values.
///
/// Values come from `env/dev.json` (never committed). Run with:
/// `flutter run --dart-define-from-file=env/dev.json`
/// Android Studio does this for you with the shared run configurations in `.run/`.
///
/// Every value has a safe default, so the app always starts in simulation mode
/// even when no env file exists.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.openWeatherApiKey,
    required this.requestedMode,
  });

  /// Reads values injected at build time.
  factory AppConfig.fromEnvironment() {
    const mode = String.fromEnvironment('DATA_MODE', defaultValue: 'simulation');
    return AppConfig(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      openWeatherApiKey: const String.fromEnvironment('OPENWEATHER_API_KEY'),
      requestedMode: mode == 'live' ? DataMode.live : DataMode.simulation,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String openWeatherApiKey;
  final DataMode requestedMode;

  /// True when real Supabase credentials were supplied.
  bool get hasSupabase =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  /// True when a weather API key was supplied.
  bool get hasWeatherKey => openWeatherApiKey.isNotEmpty;

  /// The mode actually used. Live mode silently falls back to simulation when
  /// Supabase credentials are missing, so a bad env file can never crash the demo.
  DataMode get dataMode =>
      requestedMode == DataMode.live && hasSupabase ? DataMode.live : DataMode.simulation;
}
