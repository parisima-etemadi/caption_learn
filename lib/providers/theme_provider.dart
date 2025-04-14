import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final ThemeService _themeService = ThemeService();
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Load theme mode from storage
  Future<void> _loadThemeMode() async {
    _themeMode = await _themeService.getThemeMode();
    notifyListeners();
  }
  
  // Set theme to light mode
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _themeService.saveThemeMode(_themeMode);
    notifyListeners();
  }
  
  // Set theme to dark mode
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _themeService.saveThemeMode(_themeMode);
    notifyListeners();
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }
  
  // Set theme to follow system
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _themeService.saveThemeMode(_themeMode);
    notifyListeners();
  }
} 