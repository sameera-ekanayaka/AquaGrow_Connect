import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// The only logger the app uses. Never call `print`.
///
/// Logs show in Android Studio's Logcat and Run panels, tagged with the
/// feature name so you can filter them (for example, `[dashboard]`).
///
/// ```dart
/// const _log = AppLogger('dashboard');
/// _log.info('Reading received');
/// _log.error('Failed to send command', error, stackTrace);
/// ```
class AppLogger {
  const AppLogger(this.tag);

  /// Feature or class name shown in every line.
  final String tag;

  /// Detailed diagnostic output. Debug builds only.
  void debug(String message) {
    if (kDebugMode) _write(message, level: 500);
  }

  /// Normal events worth seeing in Logcat.
  void info(String message) => _write(message, level: 800);

  /// Something unexpected that the app recovered from.
  void warning(String message, [Object? error]) =>
      _write(message, level: 900, error: error);

  /// A failure. Always pass the error and stack trace when you have them.
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _write(message, level: 1000, error: error, stackTrace: stackTrace);

  void _write(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'AquaGrow.$tag',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
