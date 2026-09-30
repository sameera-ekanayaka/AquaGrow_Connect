import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/interfaces/i_auth_repository.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/supabase_client.dart';
import '../data/auth_repository.dart';

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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  /// Signs out and resets UI state.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = const AuthUiState();
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
