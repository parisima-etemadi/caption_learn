import 'package:flutter/material.dart';
import '../../core/services/theme_service.dart';
import '../../core/utils/logger.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final ThemeService _themeService = ThemeService();
  final Logger _logger = const Logger('ThemeProvider');
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Load theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      _themeMode = await _themeService.getThemeMode();
      notifyListeners();
      _logger.i('Theme mode loaded: ${_themeMode.toString()}');
    } catch (e) {
      _logger.e('Error loading theme mode', e);
    }
  }
  
  // Set theme to light mode
  Future<void> setLightMode() async {
    try {
      _themeMode = ThemeMode.light;
      await _themeService.saveThemeMode(_themeMode);
      notifyListeners();
      _logger.i('Theme set to light mode');
    } catch (e) {
      _logger.e('Error setting light mode', e);
    }
  }
  
  // Set theme to dark mode
  Future<void> setDarkMode() async {
    try {
      _themeMode = ThemeMode.dark;
      await _themeService.saveThemeMode(_themeMode);
      notifyListeners();
      _logger.i('Theme set to dark mode');
    } catch (e) {
      _logger.e('Error setting dark mode', e);
    }
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    try {
      if (_themeMode == ThemeMode.light) {
        await setDarkMode();
      } else {
        await setLightMode();
      }
      _logger.i('Theme toggled');
    } catch (e) {
      _logger.e('Error toggling theme', e);
    }
  }
  
  // Set theme to follow system
  Future<void> setSystemMode() async {
    try {
      _themeMode = ThemeMode.system;
      await _themeService.saveThemeMode(_themeMode);
      notifyListeners();
      _logger.i('Theme set to system mode');
    } catch (e) {
      _logger.e('Error setting system mode', e);
    }
  }
} 