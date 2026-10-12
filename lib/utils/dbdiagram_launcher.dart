import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// dbdiagram is a companion Vite/React app shipped alongside SimplyMind on
/// the same origin under `/dbdiagram/`. This helper resolves the correct URL
/// for the current runtime and opens it.
///
/// - Web (release / profile): open `${current-origin}/dbdiagram/` in the
///   same tab, replacing SimplyMind (as chosen when wiring the menu item).
/// - Web (debug): open `http://localhost:5173/` so `npm run dev` inside
///   `dbdiagram/` works during local development.
/// - Native (Android / iOS): dbdiagram is web-only today, so we open the
///   production URL in an external browser.
Uri _dbDiagramUri() {
  if (kIsWeb) {
    if (kDebugMode) {
      return Uri.parse('http://localhost:5173/');
    }
    return Uri.parse('${Uri.base.origin}/dbdiagram/');
  }
  return Uri.parse('https://simplymind.nzilo.com/dbdiagram/');
}

Future<void> openDbDiagram(BuildContext context) async {
  final uri = _dbDiagramUri();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = kIsWeb
        ? await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
            // Same tab: replaces SimplyMind with dbdiagram in the current
            // browser tab. Use '_blank' here to open in a new tab instead.
            webOnlyWindowName: '_self',
          )
        : await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not open ${uri.toString()}')),
    );
  }
}
