import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class LanguageController extends ChangeNotifier {
  static final LanguageController _inst = LanguageController._();
  LanguageController._();
  static LanguageController get I => _inst;

  static const _prefsKey = 'app_locale'; // 'vi' | 'en'
  Locale _locale = const Locale('vi');
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    if (saved == 'en') {
      _locale = const Locale('en');
    } else if (saved == 'vi') {
      _locale = const Locale('vi');
    } else {
      final sys = WidgetsBinding.instance.platformDispatcher.locale;
      _locale = (sys.languageCode == 'vi') ? const Locale('vi') : const Locale('en');
    }

    Intl.defaultLocale = _locale.languageCode;
    await initializeDateFormatting(_locale.languageCode);
  }

  Future<void> setLocale(Locale l) async {
    _locale = l;
    Intl.defaultLocale = l.languageCode;
    await initializeDateFormatting(l.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, l.languageCode);
    notifyListeners(); // 🔄 Rebuild toàn app
  }

  Future<void> toggle() async {
    await setLocale(_locale.languageCode == 'vi' ? const Locale('en') : const Locale('vi'));
  }
}
