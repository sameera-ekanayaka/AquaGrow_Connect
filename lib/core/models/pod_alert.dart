import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:flutter/foundation.dart';

/// An alert raised when a reading leaves its safe range.
///
/// Created by the alert engine (Osanda's task), listed on the Alerts screen
/// and shown as a local notification.
@immutable
class PodAlert {
  const PodAlert({
    required this.id,
    required this.podId,
    required this.metric,
    required this.severity,
    required this.title,
    required this.message,
    required this.value,
    required this.createdAt,
    this.acknowledged = false,
  });

  final String id;
  final String podId;
  final SensorMetric metric;

  /// [SensorStatus.warning] or [SensorStatus.critical]. Never normal.
  final SensorStatus severity;

  /// For example "pH is too low".
  final String title;

  /// For example "Pod Alpha reads pH 4.8. Add pH-up or change the water."
  final String message;

  /// The reading that triggered the alert.
  final double value;
  final DateTime createdAt;

  /// True once the user has seen and dismissed it.
  final bool acknowledged;

  PodAlert copyWith({bool? acknowledged}) {
    return PodAlert(
      id: id,
      podId: podId,
      metric: metric,
      severity: severity,
      title: title,
      message: message,
      value: value,
      createdAt: createdAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PodAlert && other.id == id && other.acknowledged == acknowledged;

  @override
  int get hashCode => Object.hash(id, acknowledged);
}
