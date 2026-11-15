import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refreshes all telemetry and microclimate datasets presented on the Insights screen.
///
/// Invalidates historical readings, ambient weather data, and location status.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
void refreshInsightsData(WidgetRef ref) {
  ref.invalidate(historyProvider);
  ref.invalidate(weatherDataProvider);
  ref.invalidate(locationResultProvider);
}

/// Refreshes Insights datasets using a [ProviderContainer] (convenient in headless tests).
void refreshInsightsWithContainer(ProviderContainer container) {
  container.invalidate(historyProvider);
  container.invalidate(weatherDataProvider);
  container.invalidate(locationResultProvider);
}
