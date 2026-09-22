import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _service = SettingsService();

  bool _isDarkMode = false;
  bool _showGrid = true; // Grid หรือ List ในหน้า Home

  bool get isDarkMode {
    return _isDarkMode;
  }

  bool get showGrid {
    return _showGrid;
  }

  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  //* เรียกครั้งเดียวใน main ก่อน runApp
  Future<void> loadSettings() async {
    final s = await _service.loadSettings();
    _isDarkMode = s['isDarkMode']!;
    _showGrid = s['showGrid']!;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _service.saveDarkMode(value);
  }

  Future<void> setShowGrid(bool value) async {
    _showGrid = value;
    notifyListeners();
    await _service.saveShowGrid(value);
  }
}
