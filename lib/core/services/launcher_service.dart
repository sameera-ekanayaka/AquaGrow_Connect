import 'package:aquagrow_mobile/core/interfaces/i_launcher_service.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = AppLogger('LauncherService');

/// Cleans a phone number by stripping all non-digits except an optional leading `+`.
String cleanPhoneNumber(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return '';
  final hasLeadingPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return hasLeadingPlus ? '+$digits' : digits;
}

/// Concrete implementation of [ILauncherService] using `url_launcher`.
class LauncherService implements ILauncherService {
  /// Creates a launcher service.
  const LauncherService();

  @override
  Future<bool> dial(String phone) async {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      _logger.warning('Failed to launch phone dialer for number');
      return false;
    }
  }

  @override
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    // 1. Try geo URI scheme first
    final query = label != null && label.isNotEmpty
        ? '$latitude,$longitude($label)'
        : '$latitude,$longitude';
    final geoUri = Uri(
      scheme: 'geo',
      path: '$latitude,$longitude',
      queryParameters: {'q': query},
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fall through to web fallback
    }

    // 2. Web fallback to Google Maps directions
    final webUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });

    try {
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _logger.warning('Failed to launch maps directions');
    }

    return false;
  }
}
