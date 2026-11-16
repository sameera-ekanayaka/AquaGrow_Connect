/// Field rules for the Add a pod form. Pure Dart, so they are unit tested.
///
/// Each function returns an error message to show under the field, or null
/// when the value is fine.
abstract final class NewPodRules {
  /// Longest pod name or room, so it fits on the pod picker and cards.
  static const maxNameLength = 30;

  /// Pod name: required, at most [maxNameLength] characters, and not one of
  /// the user's [taken] pod names (any case), so two pods never look alike.
  static String? name(String? value, {Iterable<String> taken = const []}) {
    final error = _text(value, field: 'Pod name', example: 'Pod Gamma');
    if (error != null) return error;
    final v = value!.trim();
    final lower = v.toLowerCase();
    if (taken.any((t) => t.trim().toLowerCase() == lower)) {
      return 'You already have a pod called $v. Pick another name.';
    }
    return null;
  }

  /// Room: required, at most [maxNameLength] characters.
  static String? room(String? value) =>
      _text(value, field: 'Room', example: 'Kitchen');

  /// Serial number from the pod's label: 4 to 40 letters, digits or dashes.
  static String? serialNumber(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Serial number is required';
    if (!RegExp(r'^[A-Za-z0-9-]{4,40}$').hasMatch(v)) {
      return 'Use 4 to 40 letters, numbers or dashes, as on the label';
    }
    return null;
  }

  static String? _text(
    String? value, {
    required String field,
    required String example,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required, for example $example';
    if (v.length > maxNameLength) {
      return 'Keep it to $maxNameLength characters or fewer';
    }
    return null;
  }
}
