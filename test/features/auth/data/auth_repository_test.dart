import 'package:aquagrow_mobile/core/security/secure_storage_service.dart';
import 'package:aquagrow_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AuthRepository repo;
  late SecureStorageService storage;

  setUp(() {
    storage = SecureStorageService(
      storage: const FlutterSecureStorage(),
    );
    repo = AuthRepository(secureStorage: storage);
  });

  tearDown(() {
    repo.dispose();
  });

  group('AuthRepository simulation operations', () {
    test('updateProfile updates currentUser and emits state', () async {
      await repo.signIn(email: 'grower@example.com', password: 'password123');

      final updated = await repo.updateProfile(
        fullName: 'Kamal Silva',
        farmName: 'Ceylon Hydro Farm',
        phone: '0771234567',
      );

      expect(updated.fullName, 'Kamal Silva');
      expect(updated.farmName, 'Ceylon Hydro Farm');
      expect(updated.phone, '0771234567');

      final current = await repo.getCurrentUser();
      expect(current?.fullName, 'Kamal Silva');
    });

    test('changePassword validates new password length', () async {
      await repo.signIn(email: 'grower@example.com', password: 'password123');

      expect(
        () => repo.changePassword(
          currentPassword: 'password123',
          newPassword: '123',
        ),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        repo.changePassword(
          currentPassword: 'password123',
          newPassword: 'newsecurepass',
        ),
        completes,
      );
    });

    test('deleteAccount signs out and destroys session', () async {
      await repo.signIn(email: 'grower@example.com', password: 'password123');
      expect(repo.isAuthenticated, isTrue);

      await repo.deleteAccount(password: 'password123');
      expect(repo.isAuthenticated, isFalse);
      expect(await repo.getCurrentUser(), isNull);
    });
  });
}
