/// Form validators shared by every screen.
///
/// Each returns `null` when the value is valid, or a short message to show
/// under the field. Use them directly as a `TextFormField.validator`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Required, trimmed, valid email format.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  /// At least 8 characters with a letter and a number.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp('[A-Za-z]').hasMatch(v) || !RegExp('[0-9]').hasMatch(v)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  /// Any non-empty text.
  static String? required(String? value, {String field = 'This field'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }

  /// A number between [min] and [max], inclusive. Used for pH, EC and similar.
  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    String field = 'Value',
  }) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$field must be a number';
    if (parsed < min || parsed > max) return '$field must be between $min and $max';
    return null;
  }
}
