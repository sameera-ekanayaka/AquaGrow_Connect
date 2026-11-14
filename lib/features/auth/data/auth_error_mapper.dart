import 'dart:async';
import 'dart:io';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

/// Turns any error thrown while signing in, registering or resetting a
/// password into an [AppFailure] whose message is safe to show on screen.
///
/// Supabase error codes are listed at
/// https://supabase.com/docs/guides/auth/debugging/error-codes.
/// Raw exception text is never shown to the user; the original error is kept
/// in [AppFailure.cause] for logging.
AppFailure mapAuthError(Object error) {
  if (error is AppFailure) return error;

  if (error is AuthRetryableFetchException ||
      error is SocketException ||
      error is TimeoutException) {
    return NetworkFailure(
      'No connection. Check your internet and try again.',
      error,
    );
  }

  if (error is AuthException) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return AuthFailure('Wrong email or password.', cause: error);
    }
    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return AuthFailure(
        'Confirm your email first. Check your inbox for the link.',
        cause: error,
      );
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('already registered')) {
      return AuthFailure(
        'An account with this email already exists. Sign in instead.',
        cause: error,
      );
    }
    if (code == 'weak_password') {
      return AuthFailure(
        'Choose a stronger password with letters and numbers.',
        cause: error,
      );
    }
    if (code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        error.statusCode == '429') {
      return AuthFailure(
        'Too many attempts. Wait a minute and try again.',
        cause: error,
      );
    }
    return AuthFailure(
      'Could not reach your account. Please try again.',
      cause: error,
    );
  }

  return UnexpectedFailure('Something went wrong. Please try again.', error);
}
