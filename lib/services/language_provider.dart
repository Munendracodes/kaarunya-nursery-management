import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language state. Screens listen to this notifier and rebuild
/// when the language changes. Language is persisted via SharedPreferences.
class LanguageProvider extends ChangeNotifier {
  static const String _key = 'app_language';

  static final LanguageProvider _instance = LanguageProvider._internal();
  static LanguageProvider get instance => _instance;

  LanguageProvider._internal();

  String _language = 'EN';

  String get language => _language;

  bool get isTelugu => _language == 'TE';

  /// Load persisted language on app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_key) ?? 'EN';
    notifyListeners();
  }

  /// Persist and broadcast a language change.
  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
  }

  /// Convenience: translate based on current language.
  String t(String en, String te) => _language == 'TE' ? te : en;
}
