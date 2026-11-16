import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_control_repository.dart';
import 'package:aquagrow_mobile/core/interfaces/i_pod_repository.dart';
import 'package:aquagrow_mobile/core/interfaces/i_telemetry_repository.dart';
import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/models/crop_recipe.dart';
import 'package:aquagrow_mobile/core/models/new_pod.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_rows.dart';

/// Pods from the [PodSimulator].
class SimPodRepository implements IPodRepository {
  SimPodRepository(this._sim);

  final PodSimulator _sim;

  @override
  Stream<List<Pod>> watchPods() async* {
    yield _sim.pods;
    yield* _sim.podsStream;
  }

  @override
  Future<List<Pod>> getPods() async => _sim.pods;

  /// Adds the pod to the simulator for this session only.
  @override
  Future<Pod> addPod(NewPod pod) async {
    if (_sim.hasSerial(pod.serialNumber)) {
      throw const ValidationFailure('This serial number is already registered.');
    }
    return _sim.addPod(name: pod.name, room: pod.room, serialNumber: pod.serialNumber);
  }

  /// Plants the crop in the simulator for this session only.
  @override
  Future<void> plantCrop(String podId, CropRecipe recipe) async {
    if (_sim.pods.any((p) => p.id == podId && p.batch != null)) {
      throw const ValidationFailure('This pod already grows a crop. Harvest it first.');
    }
    _sim.plantCrop(
      podId,
      cropName: recipe.cropName,
      daysToHarvest: recipe.durationDays,
      imageAsset: SupabaseRows.cropImage(recipe.cropName),
    );
  }

  @override
  Future<void> harvest(String podId) async => _sim.harvest(podId);
}

/// Readings and history from the [PodSimulator].
class SimTelemetryRepository implements ITelemetryRepository {
  SimTelemetryRepository(this._sim);

  final PodSimulator _sim;

  @override
  Stream<SensorReading> watchReadings(String podId) async* {
    yield _sim.latest(podId);
    yield* _sim.readings.where((r) => r.deviceId == podId);
  }

  @override
  Future<SensorReading> latestReading(String podId) async => _sim.latest(podId);

  @override
  Future<List<SensorReading>> history(
    String podId, {
    required DateTime from,
    required DateTime to,
  }) async =>
      _sim.history(podId, from: from, to: to);
}

/// Pump, light and doser commands applied to the [PodSimulator].
///
/// A short delay mimics the round trip to real hardware, so loading
/// indicators are visible in the demo.
class SimControlRepository implements IControlRepository {
  SimControlRepository(this._sim, {this.latency = const Duration(milliseconds: 400)});

  final PodSimulator _sim;
  final Duration latency;

  @override
  Stream<ActuatorState> watchActuators(String podId) async* {
    yield _sim.actuators(podId);
    yield* _sim.actuatorStream(podId);
  }

  @override
  Future<void> setPump(String podId, {required bool on}) async {
    await _roundTrip(podId);
    _sim.setPump(podId, on: on);
  }

  @override
  Future<void> setLight(String podId, {required bool on, int? brightness}) async {
    await _roundTrip(podId);
    _sim.setLight(podId, on: on, brightness: brightness);
  }

  @override
  Future<PhDoseResult> dosePhDown(String podId) async {
    await _roundTrip(podId);
    return _sim.dosePhDown(podId);
  }

  @override
  Future<void> markRefilled(String podId) async {
    await _roundTrip(podId);
    _sim.refillWater(podId);
  }

  Future<void> _roundTrip(String podId) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (_sim.scenarioOf(podId) == SimScenario.sensorOffline) {
      throw const DeviceFailure('The pod is offline. Check its Wi-Fi and try again.');
    }
  }
}
