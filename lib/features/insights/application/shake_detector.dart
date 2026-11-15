import 'dart:async';
import 'package:aquagrow_mobile/features/insights/domain/shake_detector_config.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Listens to accelerometer stream and triggers a callback upon device shake gestures.
///
/// Throttles callbacks to at most once per configured interval (default 1000ms)
/// and requires g-force exceeding threshold (default 2.7g).
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class ShakeDetector {
  final Stream<AccelerometerEvent>? _injectedStream;
  final ShakeDetectorConfig config;
  final VoidCallback onShake;
  final DateTime Function() _clock;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeTime;
  bool _isPaused = false;

  /// Creates a [ShakeDetector] instance.
  ///
  /// Provide [sensorStream] to inject a test double in tests instead of listening to hardware sensors.
  ShakeDetector({
    required this.onShake,
    this.config = const ShakeDetectorConfig(),
    Stream<AccelerometerEvent>? sensorStream,
    DateTime Function()? clock,
  })  : _injectedStream = sensorStream,
        _clock = clock ?? DateTime.now;

  /// Whether the detector has an active stream subscription.
  bool get isListening => _subscription != null;

  /// Whether the detector is currently paused.
  bool get isPaused => _isPaused;

  /// The timestamp of the most recent registered shake, or null if none registered yet.
  DateTime? get lastShakeTime => _lastShakeTime;

  /// Starts listening to sensor events.
  void start() {
    if (_subscription != null) return;
    final stream = _injectedStream ?? accelerometerEventStream();
    _subscription = stream.listen(_onAccelerometerEvent);
    _isPaused = false;
  }

  /// Stops listening and cancels sensor stream subscription.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isPaused = false;
  }

  /// Pauses event listening without canceling subscription.
  void pause() {
    if (_subscription != null && !_isPaused) {
      _subscription?.pause();
      _isPaused = true;
    }
  }

  /// Resumes event listening.
  void resume() {
    if (_subscription != null && _isPaused) {
      _subscription?.resume();
      _isPaused = false;
    }
  }

  /// Resets the shake throttle state.
  void reset() {
    _lastShakeTime = null;
  }

  /// Disposes resources held by the detector.
  void dispose() {
    stop();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final gForce = ShakeMath.computeGForce(
      event.x,
      event.y,
      event.z,
      gravity: config.gravity,
    );

    if (ShakeMath.isShake(gForce, threshold: config.thresholdG)) {
      final now = _clock();
      final lastShake = _lastShakeTime;
      if (lastShake == null ||
          now.difference(lastShake) >= config.throttleDuration) {
        _lastShakeTime = now;
        onShake();
      }
    }
  }
}
