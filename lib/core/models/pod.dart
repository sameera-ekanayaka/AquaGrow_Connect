import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:flutter/foundation.dart';

/// One AquaGrow pod: the physical hydroponic unit in someone's home.
///
/// In simulation mode, pods come from the built-in simulator. In live mode,
/// they come from the Supabase `devices` table.
@immutable
class Pod {
  const Pod({
    required this.id,
    required this.name,
    required this.room,
    required this.isOnline,
    required this.lastSeenAt,
    this.batch,
  });

  /// Matches `devices.id` in Supabase and `SensorReading.deviceId`.
  final String id;

  /// Friendly name, for example "Pod Alpha".
  final String name;

  /// Where it sits, for example "Kitchen".
  final String room;

  /// False when the pod stopped reporting (for example, Wi-Fi lost).
  final bool isOnline;

  /// Time of the last reading received.
  final DateTime lastSeenAt;

  /// The crop currently growing, or null if the pod is empty.
  final CropBatch? batch;

  /// "Pod Alpha · Kitchen"
  String get displayName => '$name · $room';

  Pod copyWith({
    String? name,
    String? room,
    bool? isOnline,
    DateTime? lastSeenAt,
    CropBatch? batch,
  }) {
    return Pod(
      id: id,
      name: name ?? this.name,
      room: room ?? this.room,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      batch: batch ?? this.batch,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Pod &&
      other.id == id &&
      other.name == name &&
      other.room == room &&
      other.isOnline == isOnline &&
      other.lastSeenAt == lastSeenAt &&
      other.batch == batch;

  @override
  int get hashCode => Object.hash(id, name, room, isOnline, lastSeenAt, batch);
}
