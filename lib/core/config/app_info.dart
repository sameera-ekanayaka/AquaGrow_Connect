/// Facts about the app shown on the Settings screen.
abstract final class AppInfo {
  /// Keep in step with `version:` in pubspec.yaml (name, then build number).
  static const version = '1.0.0';

  /// Build number from pubspec.yaml (the part after `+`).
  static const buildNumber = 1;

  /// "1.0.0 (build 1)"
  static const versionLabel = '$version (build $buildNumber)';

  /// The university module this app was built for.
  static const module = 'INTE 22283 · Mobile Applications Development';

  /// The team, in task-file order.
  static const team = ['Tharindu', 'Osanda', 'Sameera', 'Imasha', 'Udeshika'];
}
