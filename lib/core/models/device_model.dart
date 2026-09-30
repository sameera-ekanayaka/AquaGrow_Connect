/// Hardware system architecture types supported by AquaGrow.
enum HydroponicSystemType {
  nft,
  dwc;

  static HydroponicSystemType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DWC':
        return HydroponicSystemType.dwc;
      case 'NFT':
      default:
        return HydroponicSystemType.nft;
    }
  }

  String toDbValue() {
    switch (this) {
      case HydroponicSystemType.dwc:
        return 'DWC';
      case HydroponicSystemType.nft:
        return 'NFT';
    }
  }

  String get displayName {
    switch (this) {
      case HydroponicSystemType.dwc:
        return 'Deep Water Culture (DWC)';
      case HydroponicSystemType.nft:
        return 'Nutrient Film Technique (NFT)';
    }
  }
}

/// Represents a registered physical AquaGrow IoT hardware unit.
class DeviceModel {
  final String id;
  final String ownerId;
  final String deviceName;
  final String serialNumber;
  final String? macAddress;
  final HydroponicSystemType systemType;
  final String firmwareVersion;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final DateTime lastSeenAt;
  final DateTime createdAt;

  const DeviceModel({
    required this.id,
    required this.ownerId,
    required this.deviceName,
    required this.serialNumber,
    this.macAddress,
    required this.systemType,
    this.firmwareVersion = '1.0.0',
    this.latitude,
    this.longitude,
    this.isOnline = false,
    required this.lastSeenAt,
    required this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      deviceName: json['device_name'] as String? ?? 'AquaGrow Unit',
      serialNumber: json['serial_number'] as String,
      macAddress: json['mac_address'] as String?,
      systemType: HydroponicSystemType.fromString(
        json['system_type'] as String? ?? 'NFT',
      ),
      firmwareVersion: json['firmware_version'] as String? ?? '1.0.0',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'device_name': deviceName,
      'serial_number': serialNumber,
      'mac_address': macAddress,
      'system_type': systemType.toDbValue(),
      'firmware_version': firmwareVersion,
      'latitude': latitude,
      'longitude': longitude,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
