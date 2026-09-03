import 'package:flutter/material.dart';

import '../../content/legal_content.dart';
import '../../l10n/app_localizations.dart';
import 'legal_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(
      title: AppLocalizations.of(context).privacyPolicy,
      sections: LegalContent.privacySections,
    );
  }
}
