import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyShowGrid = 'show_grid';

  Future<Map<String, bool>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isDarkMode': prefs.getBool(keyIsDarkMode) ?? false,
      'showGrid': prefs.getBool(keyShowGrid) ?? true,
    };
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsDarkMode, value);
  }

  Future<void> saveShowGrid(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyShowGrid, value);
  }
}
