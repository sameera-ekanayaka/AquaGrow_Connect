import 'package:aquagrow_mobile/app/app.dart';
import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:aquagrow_mobile/core/interfaces/i_auth_repository.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_service.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_notification_service.dart';

/// A signed-in demo user for widget tests.
final testUser = UserProfile(
  id: 'test-user',
  email: 'grower@aquagrow.io',
  fullName: 'Test Grower',
  role: UserRole.owner,
  createdAt: DateTime(2026, 11, 1),
);

/// Auth repository that never touches Supabase or secure storage.
class FakeAuthRepository implements IAuthRepository {
  FakeAuthRepository({this.user});

  UserProfile? user;

  @override
  Stream<UserProfile?> get authStateChanges => const Stream.empty();

  @override
  Future<UserProfile?> getCurrentUser() async => user;

  @override
  bool get isAuthenticated => user != null;

  @override
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async =>
      user;

  @override
  Future<UserProfile?> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole role = UserRole.owner,
  }) async =>
      user;

  @override
  Future<void> signOut() async => user = null;

  @override
  Future<void> resetPassword({required String email}) async {}
}

/// Builds the whole app for a widget test, with no plugins, network or timers:
/// - a fake signed-in (or signed-out) user,
/// - a simulator that does NOT tick on its own (call `sim.tick()` yourself),
/// - always online,
/// - a [FakeNotificationService] (pass your own to check notifications),
/// - preferences kept in memory.
///
/// ```dart
/// final sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
/// await tester.pumpWidget(testApp(sim: sim));
/// await tester.pump();
/// ```
Widget testApp({
  required PodSimulator sim,
  UserProfile? user,
  bool signedIn = true,
  FakeNotificationService? notifications,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: signedIn ? (user ?? testUser) : null),
      ),
      podSimulatorProvider.overrideWithValue(sim),
      isOfflineProvider.overrideWith((ref) => Stream.value(false)),
      notificationServiceProvider.overrideWithValue(
        notifications ?? FakeNotificationService(),
      ),
      preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
    ],
    child: const AquaGrowApp(),
  );
}
