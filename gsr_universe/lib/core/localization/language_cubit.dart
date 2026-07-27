// Core Localization - Language Cubit
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en', 'US')) {
    loadLanguage();
  }

  static const String keySelectedLanguage = 'selected_language';

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(keySelectedLanguage) ?? 'English';
    if (lang == 'Telugu') {
      emit(const Locale('te', 'IN'));
    } else {
      emit(const Locale('en', 'US'));
    }
  }

  Future<void> changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedLanguage, lang);
    if (lang == 'Telugu') {
      emit(const Locale('te', 'IN'));
    } else {
      emit(const Locale('en', 'US'));
    }
  }

  String get currentLanguageName {
    return state.languageCode == 'te' ? 'Telugu' : 'English';
  }
}
