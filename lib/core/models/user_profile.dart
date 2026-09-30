/// Supported user authorization tiers within the AquaGrow system.
enum UserRole {
  owner,
  viewer,
  commercialGrower;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'commercialgrower':
      case 'commercial_grower':
        return UserRole.commercialGrower;
      case 'viewer':
        return UserRole.viewer;
      case 'owner':
      default:
        return UserRole.owner;
    }
  }

  String toDbValue() {
    switch (this) {
      case UserRole.commercialGrower:
        return 'commercialGrower';
      case UserRole.viewer:
        return 'viewer';
      case UserRole.owner:
        return 'owner';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.commercialGrower:
        return 'Commercial Grower';
      case UserRole.viewer:
        return 'Staff / Viewer (Read-only)';
      case UserRole.owner:
        return 'System Owner';
    }
  }
}

/// Represents an authenticated user profile synchronized with Supabase public.profiles.
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  /// True if the user has full hardware calibration and override privileges.
  bool get canControlHardware =>
      role == UserRole.owner || role == UserRole.commercialGrower;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'owner'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role.toDbValue(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
