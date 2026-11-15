import 'dart:io';

import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every text style uses the bundled Inter font in both themes', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final t = theme.textTheme;
      for (final style in [
        t.headlineMedium,
        t.titleLarge,
        t.titleMedium,
        t.bodyLarge,
        t.labelLarge,
        t.bodySmall,
        t.displaySmall,
      ]) {
        expect(style?.fontFamily, AppTheme.fontFamily);
      }
    }
  });

  test('pubspec declares every Inter weight the theme uses', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      expect(pubspec, contains('assets/fonts/Inter-$weight.ttf'));
      expect(File('assets/fonts/Inter-$weight.ttf').existsSync(), isTrue);
    }
  });
}
