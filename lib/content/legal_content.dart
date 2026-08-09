import '../config/app_contact.dart';

/// Shared legal copy for in-app screens and static web pages.
class LegalContent {
  LegalContent._();

  static const String lastUpdated = 'August 9, 2026';

  static const List<LegalSection> privacySections = [
    LegalSection(
      title: 'Overview',
      body:
          'SimplyMind is an offline-first mind mapping application. Your mind '
          'maps are stored locally on your device as JSON. We do not operate '
          'user accounts, analytics, advertising, or cloud sync.',
    ),
    LegalSection(
      title: 'Data stored on your device',
      body:
          'All mind maps you create remain on your device unless you choose to '
          'export them. SimplyMind does not upload your map content to our '
          'servers because we do not operate backend storage for your maps.',
    ),
    LegalSection(
      title: 'Data we do not collect automatically',
      body:
          'SimplyMind does not automatically collect personal information, '
          'usage analytics, location data, contacts, or device identifiers for '
          'tracking purposes.',
    ),
    LegalSection(
      title: 'Feedback via WhatsApp',
      body:
          'If you choose to send feedback through the in-app WhatsApp link, '
          'you will open a chat with us using your WhatsApp account. We will '
          'see the message you send and whatever profile information WhatsApp '
          'shows to us. We use feedback only to improve the app and respond to '
          'you when needed.',
    ),
    LegalSection(
      title: 'Export and import',
      body:
          'You may export mind maps as JSON files and import them back at any '
          'time. You control where those files are saved and shared.',
    ),
    LegalSection(
      title: 'Children',
      body:
          'SimplyMind is not directed at children under 13, and we do not '
          'knowingly collect personal information from children.',
    ),
    LegalSection(
      title: 'Changes',
      body:
          'We may update this Privacy Policy from time to time. The "Last '
          'updated" date at the top of this page will reflect the latest '
          'version.',
    ),
    LegalSection(
      title: 'Contact',
      body:
          'Questions about this Privacy Policy may be sent to '
          '${AppContact.contactEmail}.',
    ),
  ];

  static const List<LegalSection> dmcaSections = [
    LegalSection(
      title: 'Copyright policy',
      body:
          'SimplyMind respects intellectual property rights. Because user mind '
          'map content is stored locally on each user\'s device, content in '
          'the app itself is controlled by the person using the app.',
    ),
    LegalSection(
      title: 'Reporting infringement',
      body:
          'If you believe content related to SimplyMind — including our '
          'website, app listing, branding, or other materials we publish — '
          'infringes your copyright, please send a DMCA notice with enough '
          'detail for us to review it.',
    ),
    LegalSection(
      title: 'Required information',
      body:
          'Your notice should include:\n'
          '• Your name and contact information\n'
          '• Identification of the copyrighted work claimed to be infringed\n'
          '• Identification of the material you claim is infringing\n'
          '• A statement that you have a good-faith belief the use is not authorized\n'
          '• A statement, under penalty of perjury, that the information is accurate '
          'and that you are authorized to act on behalf of the copyright owner\n'
          '• Your physical or electronic signature',
    ),
    LegalSection(
      title: 'Counter-notification',
      body:
          'If you believe material was removed or disabled by mistake, you may '
          'send a counter-notification that includes the information required '
          'under applicable law and your contact details.',
    ),
    LegalSection(
      title: 'DMCA agent contact',
      body:
          'Send DMCA notices and counter-notifications to '
          '${AppContact.contactEmail}.',
    ),
  ];
}

class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
