import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplymind/l10n/app_localizations.dart';
import 'package:simplymind/l10n/l10n_ext.dart';
import 'package:simplymind/models/mind_map.dart';

void main() {
  test('English and Indonesian localizations load key strings', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final id = await AppLocalizations.delegate.load(const Locale('id'));

    expect(en.newMindMap, 'New mind map');
    expect(id.newMindMap, isNotEmpty);
    expect(en.layoutLabel(MindMapLayout.map), 'Map');
    expect(id.layoutLabel(MindMapLayout.map), isNotEmpty);
    expect(en.categoryHome, 'Home');
    expect(id.categoryHome, isNotEmpty);
    expect(en.howToUse, 'How to use');
    expect(id.howToUse, isNotEmpty);
    expect(en.relations, 'Relations');
    expect(id.relations, isNotEmpty);
    expect(en.nodesLabel(2), contains('2'));
  });
}
