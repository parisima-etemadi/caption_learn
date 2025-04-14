import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  final Logger _logger = const Logger('ThemeService');
  
  // Save theme mode to SharedPreferences
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    try {
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
      _logger.i('Saved theme mode: ${themeMode.toString()}');
    } catch (e) {
      _logger.e('Failed to save theme mode', e);
      rethrow;
    }
  }
  
  // Load theme mode from SharedPreferences
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? value = prefs.getInt(_themeKey);
      
      if (value == null) {
        _logger.d('No saved theme mode found, using system default');
        return ThemeMode.system; // Default
      }
      
      ThemeMode themeMode;
      switch (value) {
        case 0:
          themeMode = ThemeMode.light;
          break;
        case 1:
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
      }
      
      _logger.d('Loaded theme mode: ${themeMode.toString()}');
      return themeMode;
    } catch (e) {
      _logger.e('Failed to load theme mode', e);
      return ThemeMode.system; // Default in case of error
    }
  }
} 