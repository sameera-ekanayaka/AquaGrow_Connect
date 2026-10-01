import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/core/security/secure_storage_service.dart';
import 'package:aquagrow_mobile/features/auth/data/auth_repository.dart';

/// In-memory mock implementation of FlutterSecureStorage for headless unit testing.
class InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Member 2: Hardware-Backed Secure Storage Tests', () {
    late InMemorySecureStorage mockStorage;
    late SecureStorageService secureService;

    setUp(() {
      mockStorage = InMemorySecureStorage();
      secureService = SecureStorageService(storage: mockStorage);
    });

    test('Persists and retrieves JWT auth access token', () async {
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testPayload';
      await secureService.saveAuthToken(testToken);

      final retrieved = await secureService.getAuthToken();
      expect(retrieved, equals(testToken));
    });

    test('Persists and retrieves refresh token for silent renewals', () async {
      const testRefreshToken = 'refresh-token-xyz-12345';
      await secureService.saveRefreshToken(testRefreshToken);

      final retrieved = await secureService.getRefreshToken();
      expect(retrieved, equals(testRefreshToken));
    });

    test('Persists and retrieves user role', () async {
      await secureService.saveUserRole(UserRole.commercialGrower.toDbValue());

      final retrieved = await secureService.getUserRole();
      expect(retrieved, equals('commercialGrower'));
    });

    test('Purges all credentials upon session sign out', () async {
      await secureService.saveAuthToken('token-to-delete');
      await secureService.saveRefreshToken('refresh-to-delete');
      await secureService.saveUserRole('owner');

      await secureService.clearAuthTokens();

      expect(await secureService.getAuthToken(), isNull);
      expect(await secureService.getRefreshToken(), isNull);
      expect(await secureService.getUserRole(), isNull);
    });
  });

  group('Member 2: Authentication & RBAC Layer Tests', () {
    late InMemorySecureStorage mockStorage;
    late SecureStorageService secureService;
    late AuthRepository authRepository;

    setUp(() {
      mockStorage = InMemorySecureStorage();
      secureService = SecureStorageService(storage: mockStorage);
      authRepository = AuthRepository(secureStorage: secureService);
    });

    tearDown(() {
      authRepository.dispose();
    });

    test('Sign in creates user profile and persists token to secure storage', () async {
      final user = await authRepository.signIn(
        email: 'grower@aquagrow.io',
        password: 'Password123',
      );

      expect(user, isNotNull);
      expect(user!.email, equals('grower@aquagrow.io'));
      expect(user.role, equals(UserRole.owner));
      expect(user.canControlHardware, isTrue);

      // Verify token was stored in keystore
      final token = await secureService.getAuthToken();
      expect(token, isNotNull);
      expect(token!.contains('mock-jwt-token'), isTrue);
    });

    test('Sign up with Viewer role restricts hardware control privileges', () async {
      final user = await authRepository.signUp(
        email: 'cafe_staff@aquagrow.io',
        password: 'Password123',
        fullName: 'Staff Member',
        role: UserRole.viewer,
      );

      expect(user, isNotNull);
      expect(user!.role, equals(UserRole.viewer));
      expect(user.canControlHardware, isFalse);
    });

    test('Sign up with Commercial Grower role grants full actuator control', () async {
      final user = await authRepository.signUp(
        email: 'facility@aquagrow.io',
        password: 'Password123',
        fullName: 'Greenhouse Lead',
        role: UserRole.commercialGrower,
      );

      expect(user, isNotNull);
      expect(user!.role, equals(UserRole.commercialGrower));
      expect(user.canControlHardware, isTrue);
    });

    test('Sign in throws on empty credentials (defensive validation)', () async {
      expect(
        () => authRepository.signIn(email: '', password: '123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Sign up throws on password shorter than 6 characters', () async {
      expect(
        () => authRepository.signUp(
          email: 'test@example.com',
          password: '123',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Sign out purges authenticated session and emits null', () async {
      await authRepository.signIn(
        email: 'grower@aquagrow.io',
        password: 'Password123',
      );
      expect(authRepository.isAuthenticated, isTrue);

      await authRepository.signOut();
      expect(authRepository.isAuthenticated, isFalse);
      expect(await authRepository.getCurrentUser(), isNull);
      expect(await secureService.getAuthToken(), isNull);
    });
  });

  group('Member 2: Sensor Telemetry Model and Threshold Tests', () {
    test('Correctly identifies optimal pH and out-of-bounds readings', () {
      final optimalReading = SensorReading(
        id: 'test-1',
        deviceId: 'dev-01',
        ph: 6.0,
        tdsPpm: 900,
        ecMs: 1.8,
        waterTempC: 21.0,
        waterLevelPct: 80,
        recordedAt: DateTime.now(),
      );
      expect(optimalReading.isPhOptimal(), isTrue);
      expect(optimalReading.isEcOptimal(), isTrue);
      expect(optimalReading.isWaterTempOptimal(), isTrue);
      expect(optimalReading.isWaterLevelLow(), isFalse);

      final acidicSpike = SensorReading(
        id: 'test-2',
        deviceId: 'dev-01',
        ph: 4.8,
        tdsPpm: 900,
        ecMs: 1.8,
        waterTempC: 21.0,
        waterLevelPct: 10,
        recordedAt: DateTime.now(),
      );
      expect(acidicSpike.isPhOptimal(), isFalse);
      expect(acidicSpike.isWaterLevelLow(), isTrue);
    });
  });

  group('Member 2: PostgreSQL Schema & RLS Policy Integrity Verification', () {
    test('Migration script contains mandatory tables, indexes, and RLS policies', () {
      final migrationFile = File('supabase/migrations/001_initial_schema.sql');
      expect(migrationFile.existsSync(), isTrue,
          reason: 'Migration 001_initial_schema.sql must exist on disk.');

      final sql = migrationFile.readAsStringSync();

      // Table declarations
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.profiles'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.devices'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.telemetry_logs'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.crop_recipes'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.crop_batches'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.harvest_logs'), isTrue);

      // Performance indexing for time-series charts
      expect(sql.contains('idx_telemetry_device_time'), isTrue);

      // Row-Level Security enablement
      expect(sql.contains('ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.telemetry_logs ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.crop_batches ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.harvest_logs ENABLE ROW LEVEL SECURITY;'), isTrue);

      // Declarative tenant isolation policies
      expect(sql.contains('auth.uid() = id'), isTrue);
      expect(sql.contains('auth.uid() = owner_id'), isTrue);
      expect(sql.contains('Public can verify harvest passport QR'), isTrue);
    });
  });
}
