import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  final SharedPreferences _prefs;
  bool _isDarkMode = false;

  ThemeController(this._prefs) {
    _loadThemeFromPrefs();
  }

  bool get isDarkMode => _isDarkMode;

  void _loadThemeFromPrefs() {
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}
