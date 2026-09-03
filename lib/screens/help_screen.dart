import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sections = <({IconData icon, String title, String body})>[
      (icon: Icons.home_outlined, title: l10n.helpHomeTitle, body: l10n.helpHomeBody),
      (icon: Icons.auto_awesome_outlined, title: l10n.helpCreateTitle, body: l10n.helpCreateBody),
      (icon: Icons.account_tree_outlined, title: l10n.helpEditTitle, body: l10n.helpEditBody),
      (icon: Icons.link, title: l10n.helpRelationsTitle, body: l10n.helpRelationsBody),
      (icon: Icons.zoom_out_map, title: l10n.helpCanvasTitle, body: l10n.helpCanvasBody),
      (icon: Icons.folder_outlined, title: l10n.helpOrganizeTitle, body: l10n.helpOrganizeBody),
      (icon: Icons.ios_share, title: l10n.helpExportTitle, body: l10n.helpExportBody),
      (icon: Icons.cloud_off_outlined, title: l10n.helpOfflineTitle, body: l10n.helpOfflineBody),
      (icon: Icons.language, title: l10n.helpLanguageTitle, body: l10n.helpLanguageBody),
      (icon: Icons.chat_outlined, title: l10n.helpFeedbackTitle, body: l10n.helpFeedbackBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.howToUse)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            l10n.helpIntro,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          for (final s in sections) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(s.icon, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
