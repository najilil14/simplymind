import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/mind_map.dart';

/// Export/import of mind maps as .json files.
///
/// file_picker abstracts the platform differences: on web "save" triggers a
/// browser download, on Android/iOS it opens the system save/open dialogs.
class JsonTransfer {
  /// Returns true if the file was saved, false if the user cancelled.
  static Future<bool> exportMap(MindMap map) async {
    final safeTitle = map.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final name = safeTitle.isEmpty ? 'mindmap' : safeTitle;
    final bytes = utf8.encode(map.encode(pretty: true));
    final path = await FilePicker.saveFile(
      dialogTitle: 'Export mind map',
      fileName: '$name.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    // On web the browser handles the download and the path is always null.
    return kIsWeb || path != null;
  }

  /// Returns the imported map (with a fresh id) or null if cancelled/invalid.
  static Future<MindMap?> importMap() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Import mind map',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final data = result?.files.single.bytes;
    if (data == null) return null;
    final imported = MindMap.decode(utf8.decode(data));
    // Fresh id so importing the same file twice never overwrites.
    return imported.copy(newMapId: newId());
  }
}
