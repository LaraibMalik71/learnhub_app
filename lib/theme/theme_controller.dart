import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const String _themeKey = 'selected_theme';

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static Future<void> loadTheme() async {
    final preferences = await SharedPreferences.getInstance();

    final savedTheme = preferences.getString(_themeKey);

    themeMode.value = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    _saveTheme();
  }

  static Future<void> _saveTheme() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _themeKey,
      themeMode.value == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
