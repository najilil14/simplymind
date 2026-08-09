import 'package:flutter_test/flutter_test.dart';

import 'package:simplymind/config/app_contact.dart';

void main() {
  test('WhatsApp feedback link uses the configured number and prefill', () {
    final uri = AppContact.whatsAppFeedbackUri;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/${AppContact.whatsAppNumber}');
    expect(
      uri.queryParameters['text'],
      AppContact.feedbackPrefill,
    );
  });
}
