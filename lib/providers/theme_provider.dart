import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  ThemeProvider() {
    _isDarkMode = StorageService.isDarkMode();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
