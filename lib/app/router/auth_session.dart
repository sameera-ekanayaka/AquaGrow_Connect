import 'dart:async';

import 'package:aquagrow_mobile/core/interfaces/i_auth_repository.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:flutter/foundation.dart';

/// Tracks who is signed in and tells the router when that changes.
///
/// The router listens to this (it is a [Listenable]) and re-runs its redirect,
/// so signing in or out moves the user to the right screen automatically.
/// Screens never navigate after login or logout themselves.
class AuthSession extends ChangeNotifier {
  AuthSession(this._repository) {
    _subscription = _repository.authStateChanges.listen(_set);
    unawaited(_restore());
  }

  final IAuthRepository _repository;
  late final StreamSubscription<UserProfile?> _subscription;

  UserProfile? _user;
  bool _restored = false;

  /// The signed-in user, or null.
  UserProfile? get user => _user;

  /// True once the saved session has been checked at startup.
  bool get isRestored => _restored;

  bool get isSignedIn => _user != null;

  Future<void> _restore() async {
    final current = await _repository.getCurrentUser();
    _restored = true;
    _set(current ?? _user);
  }

  void _set(UserProfile? user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
