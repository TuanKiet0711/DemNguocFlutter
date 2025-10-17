import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController _inst = ThemeController._();
  ThemeController._();
  static ThemeController get I => _inst;

  static const _prefsKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Color get backgroundColor =>
      _mode == ThemeMode.dark ? const Color(0xFF0E1515) : const Color(0xFFF3F7F7);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    switch (saved) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
  }

  Future<void> toggle() async {
    if (_mode == ThemeMode.light) {
      await _set(ThemeMode.dark);
    } else {
      await _set(ThemeMode.light);
    }
  }

  Future<void> _set(ThemeMode m) async {
    _mode = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, m == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
