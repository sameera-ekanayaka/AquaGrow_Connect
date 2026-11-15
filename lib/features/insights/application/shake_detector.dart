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

  /// Whether the detector is actively listening to accelerometer events.
  bool get isListening => _subscription != null;

  /// Starts listening to sensor events.
  void start() {
    if (_subscription != null) return;
    final stream = _injectedStream ?? accelerometerEventStream();
    _subscription = stream.listen(_onAccelerometerEvent);
  }

  /// Stops listening and cancels sensor stream subscription.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Pauses event listening without canceling subscription.
  void pause() {
    _subscription?.pause();
  }

  /// Resumes event listening.
  void resume() {
    _subscription?.resume();
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
