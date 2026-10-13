import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class TelephonyService {
  /// Dial phone number via native Android dialer
  static Future<bool> dialNumber(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
    }
    return false;
  }

  /// Launch WhatsApp with pre-filled message
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String message = '',
  }) async {
    // Strip non-digit characters except country code
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone'; // Default India country code
    }

    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    final uri = Uri.parse(url);

    try {
      if (kIsWeb) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
    return false;
  }

  /// Launch external browser URL
  static Future<bool> launchBrowser(String url) async {
    final uri = Uri.parse(url);
    try {
      if (kIsWeb) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching browser URL: $e');
      return false;
    }
  }
}
