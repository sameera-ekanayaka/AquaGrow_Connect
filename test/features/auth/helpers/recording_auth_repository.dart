import 'dart:async';

import 'package:aquagrow_mobile/core/interfaces/i_auth_repository.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An auth repository for widget tests that records every call and fails
/// with [error] when it is set.
class RecordingAuthRepository implements IAuthRepository {
  /// Creates the fake, optionally signed in as [user].
  RecordingAuthRepository({this.user});

  /// The signed-in user, or null.
  UserProfile? user;

  /// Thrown by sign in, sign up and reset when not null.
  Object? error;

  /// Emails passed to [signIn], in order.
  final signInCalls = <String>[];

  /// Emails passed to [signUp], in order.
  final signUpCalls = <String>[];

  /// Emails passed to [resetPassword], in order.
  final resetCalls = <String>[];

  /// Number of times [signOut] ran.
  int signOutCalls = 0;

  final _changes = StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> get authStateChanges => _changes.stream;

  @override
  bool get isAuthenticated => user != null;

  @override
  Future<UserProfile?> getCurrentUser() async => user;

  @override
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls.add(email);
    if (error != null) throw error!;
    return user;
  }

  @override
  Future<UserProfile?> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole role = UserRole.owner,
  }) async {
    signUpCalls.add(email);
    if (error != null) throw error!;
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    user = null;
    _changes.add(null);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    resetCalls.add(email);
    if (error != null) throw error!;
  }

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    String? farmName,
    String? phone,
  }) async {
    if (error != null) throw error!;
    user = (user ??
            UserProfile(
              id: 'u1',
              email: 'grower@aquagrow.io',
              role: UserRole.owner,
              createdAt: DateTime(2026, 11, 1),
            ))
        .copyWith(
      fullName: fullName,
      farmName: farmName,
      phone: phone,
    );
    _changes.add(user);
    return user!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (error != null) throw error!;
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    if (error != null) throw error!;
    await signOut();
  }
}

/// Shows [screen] alone, themed, with [repository] as the auth repository.
Widget authTestApp(
  Widget screen,
  RecordingAuthRepository repository, {
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: screen,
    ),
  );
}
