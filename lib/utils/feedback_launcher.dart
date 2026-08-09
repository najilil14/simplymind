import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_contact.dart';

/// Opens WhatsApp with a pre-filled SimplyMind feedback message.
///
/// On web / installed PWA, [LaunchMode.externalApplication] often fails, so
/// we open in a new tab with the platform default. On mobile apps we prefer
/// an external browser / WhatsApp app.
Future<void> openWhatsAppFeedback(BuildContext context) async {
  final uri = AppContact.whatsAppFeedbackUri;
  try {
    final launched = kIsWeb
        ? await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          )
        : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      _showFailure(context);
    }
  } catch (_) {
    // Last resort: platform default without forcing external app.
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (!launched && context.mounted) _showFailure(context);
    } catch (_) {
      if (context.mounted) _showFailure(context);
    }
  }
}

void _showFailure(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Could not open WhatsApp. Open ${AppContact.whatsAppFeedbackUri} '
        'manually, or message ${AppContact.whatsAppNumber}.',
      ),
      duration: const Duration(seconds: 6),
    ),
  );
}
