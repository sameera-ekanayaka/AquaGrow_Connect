import '../models/user_profile.dart';

/// Abstract contract governing authentication, session management, and role resolution.
/// Implemented by AuthRepository in lib/features/auth/data/.
abstract class IAuthRepository {
  /// Stream emitting user profile updates when authentication status changes.
  Stream<UserProfile?> get authStateChanges;

  /// Fetches the currently authenticated profile, or null if no valid session exists.
  Future<UserProfile?> getCurrentUser();

  /// Authenticates with email and password credentials.
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  });

  /// Registers a new user account with designated role and profile details.
  Future<UserProfile?> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole role = UserRole.owner,
  });

  /// Terminates the current session and purges persisted authentication tokens.
  Future<void> signOut();

  /// Triggers a password recovery email for the specified account.
  Future<void> resetPassword({
    required String email,
  });

  /// Checks whether an authenticated session is actively cached.
  bool get isAuthenticated;
}
