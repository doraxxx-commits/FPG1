import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/game_state.dart';

class SaveManager {
  static const String _fileName = 'fpg_save.json';

  // Pobranie ścieżki do pliku w pamięci urządzenia
  static Future<File> _getSaveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Zapis stanu gry do pliku JSON
  static Future<bool> saveGame(GameState gameState) async {
    try {
      final file = await _getSaveFile();
      final Map<String, dynamic> data = gameState.toJson();
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      print('Błąd podczas zapisu gry: $e');
      return false;
    }
  }

  // Wczytanie stanu gry z pliku JSON
  static Future<GameState?> loadGame() async {
    try {
      final file = await _getSaveFile();
      if (!await file.exists()) {
        return null;
      }
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return GameState.fromJson(data);
    } catch (e) {
      print('Błąd podczas wczytywania gry: $e');
      return null;
    }
  }

  // Sprawdzenie, czy zapis istnieje
  static Future<bool> hasSaveFile() async {
    try {
      final file = await _getSaveFile();
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
