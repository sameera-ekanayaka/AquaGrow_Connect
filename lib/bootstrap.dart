import 'dart:async';

import 'package:aquagrow_mobile/app/app.dart';
import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/network/supabase_client.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/storage/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _log = AppLogger('bootstrap');

/// Starts the app: config, local storage, Supabase (if configured), then UI.
///
/// Any startup failure is logged and the app continues in simulation mode,
/// so a missing key or a dead network can never stop the demo.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    _log.error('Flutter error', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    _log.error('Uncaught error', error, stack);
    return true;
  };

  final config = AppConfig.fromEnvironment();
  _log.info('Starting in ${config.dataMode.name} mode');

  try {
    await LocalCacheService.initialize();
    await Hive.openBox<dynamic>(AppConstants.preferencesBoxKey);
  } catch (e, st) {
    _log.error('Local cache failed to open', e, st);
  }

  if (config.hasSupabase) {
    try {
      await SupabaseManager.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );
    } catch (e, st) {
      _log.error('Supabase failed to start, staying offline', e, st);
    }
  }

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const AquaGrowApp(),
    ),
  );
}
