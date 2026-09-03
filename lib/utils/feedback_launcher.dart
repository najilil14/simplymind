import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_contact.dart';
import '../l10n/app_localizations.dart';

/// Opens WhatsApp with a pre-filled SimplyMind feedback message.
Future<void> openWhatsAppFeedback(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final uri = AppContact.whatsAppFeedbackUriFor(l10n.feedbackPrefill);
  try {
    final launched = kIsWeb
        ? await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          )
        : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      _showFailure(context, uri);
    }
  } catch (_) {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (!launched && context.mounted) _showFailure(context, uri);
    } catch (_) {
      if (context.mounted) _showFailure(context, uri);
    }
  }
}

void _showFailure(BuildContext context, Uri uri) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n.whatsAppFailed(uri.toString(), AppContact.whatsAppNumber),
      ),
      duration: const Duration(seconds: 6),
    ),
  );
}
