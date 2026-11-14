import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_auth_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/core/network/supabase_client.dart';
import 'package:aquagrow_mobile/features/auth/data/auth_error_mapper.dart';
import 'package:aquagrow_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('auth');

/// Exposes the centralized authentication repository instance.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(secureStorage: secureStorage);
});

/// Exposes a stream of authentication changes for reactive UI updates and route guarding.
final authStateChangesProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// The signed-in user, or null when signed out.
///
/// Starts with the saved session and then follows every sign-in and sign-out,
/// so screens opened later (such as Profile) still know who is signed in.
final currentUserProvider = StreamProvider<UserProfile?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield await repository.getCurrentUser();
  yield* repository.authStateChanges;
});

/// Represents the presentation state of authentication requests (login, register).
class AuthUiState {
  final bool isLoading;
  final String? errorMessage;
  final UserProfile? user;

  const AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserProfile? user,
  }) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

/// State notifier managing authentication form submissions and error states.
class AuthController extends StateNotifier<AuthUiState> {
  final IAuthRepository _repository;

  AuthController(this._repository) : super(const AuthUiState());

  /// Attempts to sign in with email and password credentials.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _messageFor(e));
      return false;
    }
  }

  /// Registers a new account with the requested role.
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole role = UserRole.owner,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _messageFor(e));
      return false;
    }
  }

  /// Signs out and resets UI state.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = const AuthUiState();
  }

  /// Sends a password reset email to [email].
  ///
  /// Returns null when the email was sent, or a message that is safe to show
  /// in the reset dialog. It does not touch the login form's error text.
  Future<String?> resetPassword(String email) async {
    try {
      await _repository.resetPassword(email: email);
      return null;
    } catch (e) {
      return _messageFor(e);
    }
  }

  /// A friendly message for [error]. Raw exception text is never shown.
  static String _messageFor(Object error) {
    final failure = error is ArgumentError
        ? ValidationFailure('${error.message}')
        : mapAuthError(error);
    if (failure is UnexpectedFailure) {
      _log.error('Auth request failed', error);
    }
    return failure.message;
  }

  /// Clears transient error messages.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Riverpod provider for AuthController UI bindings.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthUiState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
