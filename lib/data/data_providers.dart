import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/interfaces/i_alert_repository.dart';
import 'package:aquagrow_mobile/core/interfaces/i_control_repository.dart';
import 'package:aquagrow_mobile/core/interfaces/i_pod_repository.dart';
import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/core/interfaces/i_telemetry_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/data/simulation/in_memory_alert_repository.dart';
import 'package:aquagrow_mobile/data/simulation/sim_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// THE place where the app decides which data source to use.
///
/// Screens and view models only ever read the providers in this file.
/// They never create a repository or touch the simulator directly
/// (the simulator panel is the one exception).
///
/// To plug in Supabase later, change only the `switch` statements below.

const _log = AppLogger('data');

// -----------------------------------------------------------------------------
// Configuration and the simulator
// -----------------------------------------------------------------------------

/// Build settings. Overridden in `main.dart`, and in tests.
final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

/// The single pod simulator for the whole app. Starts ticking on first use.
final podSimulatorProvider = Provider<PodSimulator>((ref) {
  final sim = PodSimulator()..start();
  ref.onDispose(sim.dispose);
  return sim;
});

// -----------------------------------------------------------------------------
// Repositories
// -----------------------------------------------------------------------------

final podRepositoryProvider = Provider<IPodRepository>((ref) {
  switch (ref.watch(appConfigProvider).dataMode) {
    case DataMode.simulation:
      return SimPodRepository(ref.watch(podSimulatorProvider));
    case DataMode.live:
      // TODO(sameera): return a Supabase-backed repository here.
      _log.warning('Live pod repository not built yet, using simulation');
      return SimPodRepository(ref.watch(podSimulatorProvider));
  }
});

final telemetryRepositoryProvider = Provider<ITelemetryRepository>((ref) {
  switch (ref.watch(appConfigProvider).dataMode) {
    case DataMode.simulation:
      return SimTelemetryRepository(ref.watch(podSimulatorProvider));
    case DataMode.live:
      // TODO(sameera): return a Supabase + Hive cache repository here.
      _log.warning('Live telemetry repository not built yet, using simulation');
      return SimTelemetryRepository(ref.watch(podSimulatorProvider));
  }
});

final controlRepositoryProvider = Provider<IControlRepository>((ref) {
  return SimControlRepository(ref.watch(podSimulatorProvider));
});

final alertRepositoryProvider = Provider<IAlertRepository>((ref) {
  final repo = InMemoryAlertRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Small device-only settings (theme, permission prompts).
///
/// Uses the Hive `app_preferences` box opened in `bootstrap.dart`. If Hive did
/// not open (or in tests), falls back to memory so the app still works.
final preferencesStoreProvider = Provider<IPreferencesStore>((ref) {
  if (Hive.isBoxOpen(AppConstants.preferencesBoxKey)) {
    return HivePreferencesStore(
      Hive.box<dynamic>(AppConstants.preferencesBoxKey),
    );
  }
  _log.warning('Preferences box not open, keeping preferences in memory');
  return InMemoryPreferencesStore();
});

// -----------------------------------------------------------------------------
// Shared app state that several tabs read
// -----------------------------------------------------------------------------

/// All pods, live.
final podsProvider = StreamProvider<List<Pod>>((ref) {
  return ref.watch(podRepositoryProvider).watchPods();
});

/// The pod the user is looking at. Home, Insights and controls follow it.
final selectedPodIdProvider =
    StateProvider<String>((ref) => SimPodSeed.demo.first.id);

/// The selected pod, or null while pods are loading.
final selectedPodProvider = Provider<Pod?>((ref) {
  final id = ref.watch(selectedPodIdProvider);
  final pods = ref.watch(podsProvider).valueOrNull ?? const <Pod>[];
  for (final pod in pods) {
    if (pod.id == id) return pod;
  }
  return pods.isEmpty ? null : pods.first;
});

/// Live readings for one pod: `ref.watch(latestReadingProvider(podId))`.
final latestReadingProvider =
    StreamProvider.family<SensorReading, String>((ref, podId) {
  return ref.watch(telemetryRepositoryProvider).watchReadings(podId);
});

/// Live pump, light and doser state for one pod.
final actuatorStateProvider =
    StreamProvider.family<ActuatorState, String>((ref, podId) {
  return ref.watch(controlRepositoryProvider).watchActuators(podId);
});

/// All alerts, newest first.
final alertsProvider = StreamProvider<List<PodAlert>>((ref) {
  return ref.watch(alertRepositoryProvider).watchAlerts();
});

/// Number of alerts not yet acknowledged. Drives the bell badge.
final unreadAlertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? const <PodAlert>[];
  return alerts.where((a) => !a.acknowledged).length;
});
