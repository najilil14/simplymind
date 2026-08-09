import 'package:flutter/material.dart';

import '../../content/legal_content.dart';
import 'legal_document_screen.dart';

class DmcaScreen extends StatelessWidget {
  const DmcaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'DMCA',
      sections: LegalContent.dmcaSections,
    );
  }
}
