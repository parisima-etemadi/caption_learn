import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  
  // Save theme mode to SharedPreferences
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert ThemeMode to int for storage
    int themeModeValue;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeValue = 0;
        break;
      case ThemeMode.dark:
        themeModeValue = 1;
        break;
      default:
        themeModeValue = 2; // ThemeMode.system
    }
    
    await prefs.setInt(_themeKey, themeModeValue);
  }
  
  // Load theme mode from SharedPreferences
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final int? value = prefs.getInt(_themeKey);
    
    if (value == null) {
      return ThemeMode.system; // Default
    }
    
    switch (value) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
} 