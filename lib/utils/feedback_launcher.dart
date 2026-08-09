import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_contact.dart';

/// Opens WhatsApp with a pre-filled SimplyMind feedback message.
Future<void> openWhatsAppFeedback(BuildContext context) async {
  final uri = AppContact.whatsAppFeedbackUri;
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open WhatsApp. Please install it and try again.'),
      ),
    );
  }
}
