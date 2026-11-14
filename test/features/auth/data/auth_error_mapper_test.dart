import 'dart:async';
import 'dart:io';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/features/auth/data/auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

void main() {
  group('mapAuthError', () {
    test('turns invalid credentials into a wrong email or password message',
        () {
      final failure = mapAuthError(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Wrong email or password.');
    });

    test('recognises invalid credentials from the message alone', () {
      final failure =
          mapAuthError(const AuthException('Invalid login credentials'));
      expect(failure.message, 'Wrong email or password.');
    });

    test('asks the user to confirm their email when it is not confirmed', () {
      final failure = mapAuthError(
        const AuthException('Email not confirmed', code: 'email_not_confirmed'),
      );
      expect(failure.message, contains('Confirm your email'));
    });

    test('says the account exists when registering a used email', () {
      final failure = mapAuthError(
        const AuthException(
          'User already registered',
          code: 'user_already_exists',
        ),
      );
      expect(failure.message, contains('already exists'));
    });

    test('asks to wait when Supabase rate limits the request', () {
      final failure = mapAuthError(
        const AuthException('Too many requests', statusCode: '429'),
      );
      expect(failure.message, contains('Too many attempts'));
    });

    test('treats network problems as a NetworkFailure', () {
      expect(
        mapAuthError(AuthRetryableFetchException(message: 'fetch failed')),
        isA<NetworkFailure>(),
      );
      expect(
        mapAuthError(const SocketException('no route')),
        isA<NetworkFailure>(),
      );
      expect(mapAuthError(TimeoutException('slow')), isA<NetworkFailure>());
    });

    test('never shows the raw text of an unknown auth error', () {
      final failure = mapAuthError(
        const AuthException('pq: internal stack detail', code: 'unexpected'),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, isNot(contains('pq:')));
    });

    test('wraps any other error as an UnexpectedFailure and keeps the cause',
        () {
      final error = StateError('boom');
      final failure = mapAuthError(error);
      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, isNot(contains('boom')));
      expect(failure.cause, same(error));
    });

    test('passes an existing AppFailure through unchanged', () {
      const failure = AuthFailure('Session expired.');
      expect(mapAuthError(failure), same(failure));
    });
  });
}
