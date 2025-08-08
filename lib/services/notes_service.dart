
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NotesService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('\$path/notes.txt');
  }

  Future<List<String>> readNotes() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return contents.split('\n').where((note) => note.trim().isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeNote(String note) async {
    final file = await _localFile;
    await file.writeAsString('\$note\n', mode: FileMode.append);
  }
}
