/// Public contact details used in legal pages and feedback links.
class AppContact {
  AppContact._();

  static const String appName = 'SimplyMind';
  static const String contactEmail = 'naziloasr@gmail.com';
  static const String whatsAppNumber = '6285161161477';

  /// Pre-filled first line when opening WhatsApp feedback (English fallback).
  static const String feedbackPrefill =
      "I'm using SimplyMind and I have some feedback for you: ";

  static Uri whatsAppFeedbackUriFor(String text) => Uri.parse(
        'https://wa.me/$whatsAppNumber?text=${Uri.encodeComponent(text)}',
      );

  static Uri get whatsAppFeedbackUri =>
      whatsAppFeedbackUriFor(feedbackPrefill);

  static Uri get mailtoUri =>
      Uri(scheme: 'mailto', path: contactEmail);
}
