/// A failure the user can be told about.
///
/// Repositories catch low-level exceptions (Supabase, Hive, HTTP) and rethrow
/// them as an [AppFailure] with a message that is safe to show on screen.
/// Screens never see raw exceptions or stack traces.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  /// Short, friendly text that is safe to show to the user.
  final String message;

  /// The original exception, kept for logging only. Never shown in the UI.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connection, timeout, or server unreachable.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No connection. Showing saved data.', Object? cause])
      : super(cause: cause);
}

/// Wrong password, expired session, or no permission (RLS).
final class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.cause});
}

/// User input failed validation, for example a pH outside 0 to 14.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// The pod rejected or did not acknowledge a command.
final class DeviceFailure extends AppFailure {
  const DeviceFailure(super.message, {super.cause});
}

/// Reading or writing local storage failed.
final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

/// Anything else. Log the cause and show a generic message.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Something went wrong. Please try again.', Object? cause])
      : super(cause: cause);
}
