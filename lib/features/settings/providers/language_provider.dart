import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
final languageProvider =
    NotifierProvider<LanguageNotifier, Locale>(LanguageNotifier.new);
class LanguageNotifier extends Notifier<Locale> {
  static const String _languageKey = 'app_language';
  @override
  Locale build() {
    _loadLanguage();
    return const Locale('it');
  }
  Future<void> _loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_languageKey);
    if (savedLanguage != null) {
      state = Locale(savedLanguage);
    }
  }
  Future<void> setLanguage(Locale locale) async {
    state = locale;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _languageKey,
      locale.languageCode,
    );
  }
}