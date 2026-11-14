import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_auth_repository.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// An auth repository that throws [error] from every call.
class _FailingAuthRepository implements IAuthRepository {
  _FailingAuthRepository(this.error);

  final Object error;

  @override
  Stream<UserProfile?> get authStateChanges => const Stream.empty();

  @override
  bool get isAuthenticated => false;

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) =>
      Future.error(error);

  @override
  Future<UserProfile?> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole role = UserRole.owner,
  }) =>
      Future.error(error);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) => Future.error(error);
}

void main() {
  group('AuthController', () {
    test('shows the AppFailure message when sign in fails', () async {
      final controller = AuthController(
        _FailingAuthRepository(const AuthFailure('Wrong email or password.')),
      );

      final ok = await controller.signIn('grower@aquagrow.io', 'Wrong1234');

      expect(ok, isFalse);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, 'Wrong email or password.');
    });

    test('maps a raw Supabase error instead of showing its text', () async {
      final controller = AuthController(
        _FailingAuthRepository(
          const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        ),
      );

      await controller.signIn('grower@aquagrow.io', 'Wrong1234');

      expect(controller.state.errorMessage, 'Wrong email or password.');
      expect(controller.state.errorMessage, isNot(contains('AuthException')));
    });

    test('hides unexpected error text behind a generic message', () async {
      final controller =
          AuthController(_FailingAuthRepository(StateError('stack trace')));

      await controller.signUp(email: 'a@b.co', password: 'Password123');

      expect(
        controller.state.errorMessage,
        'Something went wrong. Please try again.',
      );
    });

    test('resetPassword returns null when the email was sent', () async {
      final controller = AuthController(_ResettingAuthRepository());

      expect(await controller.resetPassword('grower@aquagrow.io'), isNull);
    });

    test('resetPassword returns a friendly message when it fails', () async {
      final controller = AuthController(
        _FailingAuthRepository(
          const AuthException('Too many requests', statusCode: '429'),
        ),
      );

      final message = await controller.resetPassword('grower@aquagrow.io');

      expect(message, contains('Too many attempts'));
      expect(controller.state.errorMessage, isNull);
    });
  });
}

/// An auth repository whose password reset always succeeds.
class _ResettingAuthRepository extends _FailingAuthRepository {
  _ResettingAuthRepository() : super(StateError('unused'));

  @override
  Future<void> resetPassword({required String email}) async {}
}
