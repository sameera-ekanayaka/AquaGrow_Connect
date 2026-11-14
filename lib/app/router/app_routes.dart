/// Every route path in the app. Navigate with `context.go(AppRoutes.home)`
/// or `context.push(AppRoutes.alerts)`. Never type a path string elsewhere.
///
/// - `go` replaces the current location (switching tabs, after login).
/// - `push` opens a screen on top, with a back arrow (alerts, detail screens).
abstract final class AppRoutes {
  // Signed out
  static const login = '/login';
  static const register = '/register';

  // The four bottom-navigation tabs (Figma: Home, Crops, Insights, Care)
  static const home = '/home';
  static const crops = '/crops';
  static const insights = '/insights';
  static const care = '/care';

  // Opened on top of a tab
  static const alerts = '/alerts';
  static const profile = '/profile';
  static const simulator = '/simulator';
  static const settings = '/settings';
  static const supplierMap = '/care/suppliers';
  static const microclimate = '/insights/microclimate';

  /// Crop detail for one pod: `context.push(AppRoutes.cropDetail('pod-alpha'))`.
  static String cropDetail(String podId) => '/crops/$podId';
  static const cropDetailPattern = '/crops/:podId';

  /// Routes reachable without signing in.
  static const publicRoutes = {login, register};
}
