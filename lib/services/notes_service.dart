import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NotesService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    // FIX: proper interpolation
    return File('$path/notes.txt');
  }

  /// Read all notes as raw lines.
  Future<List<String>> readNotes() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      return contents
          .split('\n')
          .map((s) => s.trim())
          .where((note) => note.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Append a note line (backward-compatible).
  /// Pass text only (HomeScreen) or "EMOJI|||text" (NotesScreen).
  Future<void> writeNote(String noteLine) async {
    final file = await _localFile;
    await file.writeAsString('$noteLine\n', mode: FileMode.append, flush: true);
  }

  /// Overwrite the file with the provided lines (used for deletes).
  Future<void> rewriteNotes(List<String> lines) async {
    final file = await _localFile;
    final data = lines.isEmpty ? '' : (lines.join('\n') + '\n');
    await file.writeAsString(data, mode: FileMode.write, flush: true);
  }

  /// Helper to build an encoded line with emoji.
  static String encodeWithEmoji(String emoji, String text) => '$emoji|||$text';
}