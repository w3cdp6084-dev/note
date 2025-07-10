import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._prefs) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // システムの設定に従う場合は、現在のplatformBrightnessを参照
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isSystemMode => _themeMode == ThemeMode.system;

  void _loadThemeMode() {
    final themeIndex = _prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }

  IconData get currentThemeIcon {
    switch (_themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_4;
    }
  }

  String get currentThemeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'システム設定';
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
    }
  }
} 