import 'package:flutter/foundation.dart';

/// How a pod grows its plants. Matches `devices.system_type` in Supabase.
enum PodSystemType {
  /// Nutrient film technique: a thin film of water runs past the roots.
  nft('NFT', 'A thin film of water runs past the roots.'),

  /// Deep water culture: the roots sit in the water.
  dwc('DWC', 'The roots sit in the water.');

  const PodSystemType(this.code, this.description);

  /// The value stored in the database, for example "NFT".
  final String code;

  /// One plain sentence for the Add a pod form.
  final String description;
}

/// What the user enters to add a pod. The repository gives it an id.
@immutable
class NewPod {
  /// A pod to add. Text is trimmed and the serial number upper-cased, so
  /// " aqg-01 " and "AQG-01" count as the same pod.
  NewPod({
    required String name,
    required String room,
    required String serialNumber,
    required this.systemType,
  })  : name = name.trim(),
        room = room.trim(),
        serialNumber = serialNumber.trim().toUpperCase();

  /// Friendly name, for example "Pod Gamma".
  final String name;

  /// Where it sits, for example "Balcony".
  final String room;

  /// The serial number on the pod's label. Unique across all pods.
  final String serialNumber;

  /// NFT or DWC.
  final PodSystemType systemType;

  @override
  bool operator ==(Object other) =>
      other is NewPod &&
      other.name == name &&
      other.room == room &&
      other.serialNumber == serialNumber &&
      other.systemType == systemType;

  @override
  int get hashCode => Object.hash(name, room, serialNumber, systemType);
}
