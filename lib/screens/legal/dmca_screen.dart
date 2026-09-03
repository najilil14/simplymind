import 'package:flutter/material.dart';

import '../../content/legal_content.dart';
import '../../l10n/app_localizations.dart';
import 'legal_document_screen.dart';

class DmcaScreen extends StatelessWidget {
  const DmcaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(
      title: AppLocalizations.of(context).dmca,
      sections: LegalContent.dmcaSections,
    );
  }
}
