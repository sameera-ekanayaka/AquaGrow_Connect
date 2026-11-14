import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.dataMode', () {
    test('falls back to simulation when live is requested without Supabase', () {
      const config = AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        openWeatherApiKey: '',
        requestedMode: DataMode.live,
      );

      expect(config.hasSupabase, isFalse);
      expect(config.dataMode, DataMode.simulation);
    });

    test('uses live mode when Supabase credentials are present', () {
      const config = AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
        openWeatherApiKey: '',
        requestedMode: DataMode.live,
      );

      expect(config.dataMode, DataMode.live);
    });

    test('defaults to simulation with no environment values', () {
      final config = AppConfig.fromEnvironment();

      expect(config.dataMode, DataMode.simulation);
      expect(config.hasWeatherKey, isFalse);
    });
  });
}
