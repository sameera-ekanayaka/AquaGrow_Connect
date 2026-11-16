import 'dart:async';
import 'dart:math';

import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';

export 'package:aquagrow_mobile/core/simulation/sim_scenario.dart';

/// Starting values for one simulated pod.
class SimPodSeed {
  const SimPodSeed({
    required this.id,
    required this.name,
    required this.room,
    required this.cropName,
    required this.plantedDaysAgo,
    required this.daysToHarvest,
    this.imageAsset,
    this.ph = 6.0,
    this.ec = 1.8,
    this.waterTemp = 21.5,
    this.waterLevel = 80,
  });

  final String id;
  final String name;
  final String room;
  final String cropName;
  final int plantedDaysAgo;
  final int daysToHarvest;
  final String? imageAsset;
  final double ph;
  final double ec;
  final double waterTemp;
  final double waterLevel;

  /// The two demo pods, matching the Figma screens.
  static const demo = [
    SimPodSeed(
      id: 'pod-alpha',
      name: 'Pod Alpha',
      room: 'Kitchen',
      cropName: 'Genovese Basil',
      plantedDaysAgo: 8,
      daysToHarvest: 28,
      imageAsset: 'assets/images/crops/basil.png',
      ph: 6.2,
      waterTemp: 22,
      waterLevel: 64,
    ),
    SimPodSeed(
      id: 'pod-beta',
      name: 'Pod Beta',
      room: 'Dining room',
      cropName: 'Baby Spinach',
      plantedDaysAgo: 3,
      daysToHarvest: 35,
      imageAsset: 'assets/images/crops/spinach.png',
      ph: 6.0,
      ec: 1.6,
      waterTemp: 20.5,
      waterLevel: 86,
    ),
  ];
}

/// A software stand-in for the AquaGrow pod hardware (ESP32 + sensors + pump).
///
/// It produces realistic, slowly drifting readings, reacts to the pump, light
/// and pH doser, and can be pushed into failure [SimScenario]s on demand.
/// Everything in the demo runs on this, so it needs no hardware and no network.
///
/// How it works:
/// - Each pod has a current value and a *target* for every metric. On every
///   [tick], each value moves 10% of the way to its target, plus a little noise.
/// - Scenarios and controls change the targets (and sometimes the values),
///   so changes look gradual and believable on charts.
/// - Water level only goes down (evaporation and plant uptake) until refilled.
///
/// Time and randomness are injectable, so tests are fully deterministic:
/// call [tick] directly instead of [start].
class PodSimulator {
  PodSimulator({
    List<SimPodSeed> seeds = SimPodSeed.demo,
    int seed = 42,
    DateTime Function()? clock,
  })  : _random = Random(seed),
        _seed = seed,
        _now = clock ?? DateTime.now {
    final now = _now();
    for (final s in seeds) {
      _pods[s.id] = _SimPod.fromSeed(s, now);
    }
  }

  static const _log = AppLogger('simulator');

  /// Each tick nudges values 10% toward their targets.
  static const double _approachRate = 0.10;

  /// Water lost per tick while the pump runs (percentage points).
  static const double _waterUsePerTick = 0.04;

  /// pH drop from one pH-down pulse.
  static const double phDoseStep = 0.15;

  /// Live readings kept per pod for charts (about 16 minutes at 2 s per tick).
  static const int _bufferSize = 500;

  final Random _random;
  final int _seed;
  final DateTime Function() _now;
  final Map<String, _SimPod> _pods = {};

  /// Serial numbers of pods added with [addPod], upper-cased.
  final Set<String> _serials = {};
  int _tickCount = 0;
  Timer? _timer;

  final _readings = StreamController<SensorReading>.broadcast();
  final _podsChanged = StreamController<List<Pod>>.broadcast();
  final _actuatorsChanged = StreamController<MapEntry<String, ActuatorState>>.broadcast();

  // ---------------------------------------------------------------------------
  // Reading state
  // ---------------------------------------------------------------------------

  /// Every pod, in a stable order.
  List<Pod> get pods => _pods.values.map((p) => p.toPod()).toList(growable: false);

  /// Emits the full pod list whenever any pod changes (online state, batch).
  Stream<List<Pod>> get podsStream => _podsChanged.stream;

  /// Emits every new reading from every online pod.
  Stream<SensorReading> get readings => _readings.stream;

  /// Emits the actuator state of [podId] whenever it changes.
  Stream<ActuatorState> actuatorStream(String podId) =>
      _actuatorsChanged.stream.where((e) => e.key == podId).map((e) => e.value);

  /// Whether a pod with [serialNumber] was already added (any case).
  bool hasSerial(String serialNumber) => _serials.contains(serialNumber.trim().toUpperCase());

  /// Adds a pod with no crop yet and returns it. Its readings start at the
  /// healthy defaults and follow the same physics as the demo pods.
  ///
  /// Throws an [ArgumentError] if [serialNumber] was already added.
  Pod addPod({required String name, required String room, required String serialNumber}) {
    final serial = serialNumber.trim().toUpperCase();
    if (_serials.contains(serial)) {
      throw ArgumentError.value(serialNumber, 'serialNumber', 'Already added');
    }
    final slug = serial.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
    var id = 'pod-$slug';
    for (var n = 2; _pods.containsKey(id); n++) {
      id = 'pod-$slug-$n';
    }
    final pod = _SimPod.empty(
      SimPodSeed(id: id, name: name.trim(), room: room.trim(), cropName: '', plantedDaysAgo: 0, daysToHarvest: 0),
      _now(),
    );
    _pods[id] = pod;
    _serials.add(serial);
    _log.info('Pod added: $id');
    _emitPods();
    _emitNow(pod);
    return pod.toPod();
  }

  /// Plants [cropName] in [podId] today, growing for [daysToHarvest] days.
  ///
  /// Throws a [StateError] if the pod already grows a crop.
  void plantCrop(String podId, {required String cropName, required int daysToHarvest, String? imageAsset}) {
    final pod = _pod(podId);
    if (pod.batch != null) throw StateError('$podId already grows ${pod.batch!.cropName}');
    final now = _now();
    pod.batch = CropBatch(
      id: '$podId-batch-${now.microsecondsSinceEpoch}',
      podId: podId,
      cropName: cropName,
      imageAsset: imageAsset,
      plantedAt: DateTime(now.year, now.month, now.day),
      daysToHarvest: daysToHarvest,
    );
    _emitPods();
  }

  /// Removes the crop from [podId] after harvest, so the pod is empty again.
  void harvest(String podId) {
    _pod(podId).batch = null;
    _emitPods();
  }

  /// The most recent reading for [podId].
  SensorReading latest(String podId) => _pod(podId).toReading(_now(), _tickCount);

  /// Current actuator state for [podId].
  ActuatorState actuators(String podId) => _pod(podId).actuators;

  /// Active scenario for [podId].
  SimScenario scenarioOf(String podId) => _pod(podId).scenario;

  /// Whether the timer started by [start] is running.
  bool get isRunning => _timer?.isActive ?? false;

  /// Readings for [podId] between [from] and [to], oldest first.
  ///
  /// Hourly points before the app started are generated from a daily cycle
  /// (warmer and higher pH in the afternoon), so charts have a believable
  /// week of history on first launch. Live readings are appended after that.
  List<SensorReading> history(String podId, {required DateTime from, required DateTime to}) {
    final pod = _pod(podId);
    final points = <SensorReading>[];

    var t = DateTime(from.year, from.month, from.day, from.hour);
    final backfillEnd = pod.startedAt.isBefore(to) ? pod.startedAt : to;
    while (t.isBefore(backfillEnd)) {
      if (!t.isBefore(from)) points.add(_backfillPoint(pod, t));
      t = t.add(const Duration(hours: 1));
    }

    points.addAll(
      pod.buffer.where((r) => !r.recordedAt.isBefore(from) && !r.recordedAt.isAfter(to)),
    );
    return points;
  }

  // ---------------------------------------------------------------------------
  // Running
  // ---------------------------------------------------------------------------

  /// Starts producing a reading per pod every [interval].
  void start({Duration interval = const Duration(seconds: 2)}) {
    if (isRunning) return;
    _log.info('Simulator started (${_pods.length} pods, every ${interval.inSeconds}s)');
    _timer = Timer.periodic(interval, (_) => tick());
  }

  /// Pauses the simulation. Readings stop until [start] is called again.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Advances every pod by one step and emits one reading per online pod.
  void tick() {
    _tickCount++;
    final now = _now();
    for (final pod in _pods.values) {
      if (pod.scenario == SimScenario.sensorOffline) continue;

      pod
        ..ph = _approach(pod.ph, pod.phTarget, 0.02)
        ..ec = _approach(pod.ec, pod.ecTarget, 0.02)
        ..waterTemp = _approach(pod.waterTemp, pod.effectiveWaterTempTarget, 0.05)
        ..ambientTemp = _approach(pod.ambientTemp, pod.effectiveAmbientTarget, 0.05)
        ..humidity = _approach(pod.humidity, pod.humidityTarget, 0.3);

      if (pod.actuators.pumpOn) {
        pod.waterLevel = max(0.0, pod.waterLevel - _waterUsePerTick);
      }

      final reading = pod.toReading(now, _tickCount);
      pod.lastSeenAt = now;
      pod.buffer.add(reading);
      if (pod.buffer.length > _bufferSize) pod.buffer.removeAt(0);
      _readings.add(reading);
    }
  }

  // ---------------------------------------------------------------------------
  // Scenarios
  // ---------------------------------------------------------------------------

  /// Puts [podId] into [scenario]. See [SimScenario] for what each one does.
  void applyScenario(String podId, SimScenario scenario) {
    final pod = _pod(podId);
    final wasOffline = pod.scenario == SimScenario.sensorOffline;
    pod.resetTargets();
    pod.scenario = scenario;

    switch (scenario) {
      case SimScenario.normal:
        pod
          ..waterLevel = 95
          ..actuators = pod.actuators.copyWith(phDosesWithoutChange: 0);
      case SimScenario.acidSpike:
        pod
          ..ph = 4.8
          ..phTarget = 4.8;
      case SimScenario.alkalineDrift:
        pod
          ..ph = 7.4
          ..phTarget = 7.4;
      case SimScenario.lowWater:
        pod.waterLevel = 12;
      case SimScenario.heatwave:
        pod
          ..waterTemp = 27.5
          ..waterTempTarget = 29
          ..ambientTarget = 34;
      case SimScenario.nutrientDepletion:
        pod
          ..ec = 0.5
          ..ecTarget = 0.5;
      case SimScenario.doserEmpty:
        pod
          ..ph = 7.0
          ..phTarget = 7.0;
      case SimScenario.sensorOffline:
        break;
    }

    _log.info('${pod.name}: scenario ${scenario.name}');
    _emitActuators(pod);
    if (wasOffline || scenario == SimScenario.sensorOffline) _emitPods();
    if (scenario != SimScenario.sensorOffline) _emitNow(pod);
  }

  // ---------------------------------------------------------------------------
  // Controls (what the app's pump, light and doser buttons call)
  // ---------------------------------------------------------------------------

  /// Turns the circulation pump on or off. With the pump off, water warms up.
  void setPump(String podId, {required bool on}) {
    final pod = _pod(podId);
    pod.actuators = pod.actuators.copyWith(pumpOn: on);
    _emitActuators(pod);
  }

  /// Turns the ultrasonic mist maker on or off.
  void setMist(String podId, {required bool on}) {
    final pod = _pod(podId);
    pod.actuators = pod.actuators.copyWith(mistOn: on);
    _emitActuators(pod);
  }

  /// Turns the grow light on or off and optionally sets brightness (0 to 100).
  void setLight(String podId, {required bool on, int? brightness}) {
    final pod = _pod(podId);
    pod.actuators = pod.actuators.copyWith(
      lightOn: on,
      lightBrightness: brightness == null ? null : max(0, min(100, brightness)),
    );
    _emitActuators(pod);
  }

  /// Runs one pH-down pulse.
  ///
  /// Lowers pH by [phDoseStep] unless the doser is empty. After
  /// [ActuatorState.maxDosesWithoutChange] pulses with no effect, dosing locks.
  PhDoseResult dosePhDown(String podId) {
    final pod = _pod(podId);
    if (pod.actuators.dosingLocked) return PhDoseResult.locked;

    final now = _now();
    if (pod.scenario == SimScenario.doserEmpty) {
      pod.actuators = pod.actuators.copyWith(
        lastPhDoseAt: now,
        phDosesWithoutChange: pod.actuators.phDosesWithoutChange + 1,
      );
      _emitActuators(pod);
      _log.warning('${pod.name}: pH dose had no effect '
          '(${pod.actuators.phDosesWithoutChange}/${ActuatorState.maxDosesWithoutChange})');
      return pod.actuators.dosingLocked ? PhDoseResult.locked : PhDoseResult.noEffect;
    }

    pod
      ..ph = max(4.0, pod.ph - phDoseStep)
      ..phTarget = max(4.0, pod.phTarget - phDoseStep)
      ..actuators = pod.actuators.copyWith(lastPhDoseAt: now, phDosesWithoutChange: 0);
    _emitActuators(pod);
    _emitNow(pod);
    return PhDoseResult.applied;
  }

  /// Refills the reservoir to 100%.
  void refillWater(String podId) {
    final pod = _pod(podId);
    pod.waterLevel = 100;
    if (pod.scenario == SimScenario.lowWater) pod.scenario = SimScenario.normal;
    _emitNow(pod);
  }

  /// Stops the timer and closes all streams. Call once, when the app closes.
  void dispose() {
    stop();
    _readings.close();
    _podsChanged.close();
    _actuatorsChanged.close();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  _SimPod _pod(String podId) {
    final pod = _pods[podId];
    if (pod == null) throw ArgumentError.value(podId, 'podId', 'Unknown pod');
    return pod;
  }

  double _approach(double value, double target, double noise) {
    final jitter = (_random.nextDouble() - 0.5) * 2 * noise;
    return value + (target - value) * _approachRate + jitter;
  }

  void _emitNow(_SimPod pod) {
    final reading = pod.toReading(_now(), _tickCount);
    pod.buffer.add(reading);
    if (pod.buffer.length > _bufferSize) pod.buffer.removeAt(0);
    _readings.add(reading);
  }

  void _emitPods() => _podsChanged.add(pods);

  void _emitActuators(_SimPod pod) =>
      _actuatorsChanged.add(MapEntry(pod.id, pod.actuators));

  SensorReading _backfillPoint(_SimPod pod, DateTime t) {
    // Deterministic per pod and hour: same chart every launch.
    final r = Random(_seed ^ pod.id.hashCode ^ t.millisecondsSinceEpoch ~/ 3600000);
    final dayCycle = sin((t.hour - 9) / 24 * 2 * pi); // peaks mid-afternoon
    double n(double size) => (r.nextDouble() - 0.5) * 2 * size;
    final hoursBeforeStart = pod.startedAt.difference(t).inHours;
    return SensorReading(
      id: '${pod.id}-h${t.millisecondsSinceEpoch}',
      deviceId: pod.id,
      ph: pod.baseline.ph + 0.15 * dayCycle + n(0.05),
      ecMs: pod.baseline.ec + 0.1 * dayCycle + n(0.04),
      tdsPpm: (pod.baseline.ec + 0.1 * dayCycle) * 500,
      waterTempC: pod.baseline.waterTemp + 1.2 * dayCycle + n(0.2),
      ambientTempC: 28 + 3 * dayCycle + n(0.4),
      humidityPct: 72 - 8 * dayCycle + n(1),
      // Level was higher in the past: about 0.15% used per hour.
      waterLevelPct: min(100.0, pod.baseline.waterLevel + hoursBeforeStart * 0.15),
      recordedAt: t,
    );
  }
}

/// Mutable internal state of one simulated pod. Never leaves this file.
class _SimPod {
  _SimPod({
    required this.baseline,
    required this.startedAt,
    required this.ph,
    required this.ec,
    required this.waterTemp,
    required this.waterLevel,
    required this.batch,
  })  : phTarget = baseline.ph,
        ecTarget = baseline.ec,
        waterTempTarget = baseline.waterTemp,
        lastSeenAt = startedAt;

  /// A pod the user just added: default healthy water and no crop yet.
  factory _SimPod.empty(SimPodSeed s, DateTime now) {
    return _SimPod(
      baseline: s,
      startedAt: now,
      ph: s.ph,
      ec: s.ec,
      waterTemp: s.waterTemp,
      waterLevel: s.waterLevel,
      batch: null,
    );
  }

  factory _SimPod.fromSeed(SimPodSeed s, DateTime now) {
    return _SimPod(
      baseline: s,
      startedAt: now,
      ph: s.ph,
      ec: s.ec,
      waterTemp: s.waterTemp,
      waterLevel: s.waterLevel,
      batch: CropBatch(
        id: '${s.id}-batch-1',
        podId: s.id,
        cropName: s.cropName,
        imageAsset: s.imageAsset,
        plantedAt: DateTime(now.year, now.month, now.day).subtract(Duration(days: s.plantedDaysAgo)),
        daysToHarvest: s.daysToHarvest,
      ),
    );
  }

  final SimPodSeed baseline;
  final DateTime startedAt;

  /// The crop growing now, or null for an empty pod.
  CropBatch? batch;
  final List<SensorReading> buffer = [];

  String get id => baseline.id;
  String get name => baseline.name;

  double ph;
  double ec;
  double waterTemp;
  double waterLevel;
  double ambientTemp = 28;
  double humidity = 70;

  double phTarget;
  double ecTarget;
  double waterTempTarget;
  double ambientTarget = 28;
  double humidityTarget = 70;

  ActuatorState actuators = ActuatorState.initial;
  SimScenario scenario = SimScenario.normal;
  DateTime lastSeenAt;

  /// Still water with the pump off warms up by about 3°C.
  double get effectiveWaterTempTarget => waterTempTarget + (actuators.pumpOn ? 0 : 3);

  /// The grow light adds a little heat around the pod.
  double get effectiveAmbientTarget => ambientTarget + (actuators.lightOn ? 1 : 0);

  void resetTargets() {
    phTarget = baseline.ph;
    ecTarget = baseline.ec;
    waterTempTarget = baseline.waterTemp;
    ambientTarget = 28;
    humidityTarget = 70;
  }

  Pod toPod() => Pod(
        id: id,
        name: name,
        room: baseline.room,
        isOnline: scenario != SimScenario.sensorOffline,
        lastSeenAt: lastSeenAt,
        batch: batch,
      );

  SensorReading toReading(DateTime now, int tick) => SensorReading(
        id: '$id-t$tick-${now.microsecondsSinceEpoch}',
        deviceId: id,
        ph: _round(ph, 2),
        ecMs: _round(ec, 2),
        tdsPpm: _round(ec * 500, 0),
        waterTempC: _round(waterTemp, 1),
        ambientTempC: _round(ambientTemp, 1),
        humidityPct: _round(humidity, 0),
        waterLevelPct: _round(waterLevel, 1),
        recordedAt: now,
      );

  static double _round(double v, int places) {
    final f = pow(10, places);
    return (v * f).roundToDouble() / f;
  }
}
