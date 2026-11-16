import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile model tests', () {
    test('supports farmName and phone fields in json serialization', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final profile = UserProfile(
        id: 'user-123',
        email: 'grower@example.com',
        fullName: 'Jane Doe',
        farmName: 'Green Horizon Farm',
        phone: '0771234567',
        role: UserRole.owner,
        createdAt: now,
      );

      final json = profile.toJson();
      expect(json['farm_name'], 'Green Horizon Farm');
      expect(json['phone'], '0771234567');

      final restored = UserProfile.fromJson(json);
      expect(restored.id, 'user-123');
      expect(restored.fullName, 'Jane Doe');
      expect(restored.farmName, 'Green Horizon Farm');
      expect(restored.phone, '0771234567');
      expect(restored.role, UserRole.owner);
    });

    test('copyWith updates farmName and phone correctly', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final initial = UserProfile(
        id: 'user-1',
        email: 'user@example.com',
        role: UserRole.owner,
        createdAt: now,
      );

      final updated = initial.copyWith(
        farmName: 'Aqua Leaf',
        phone: '0719876543',
      );

      expect(updated.farmName, 'Aqua Leaf');
      expect(updated.phone, '0719876543');
      expect(updated.id, 'user-1');
    });
  });
}
