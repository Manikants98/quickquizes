import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  String _selectedColor = 'green';

  bool get isDarkMode => _isDarkMode;
  String get selectedColor => _selectedColor;

  static const Map<String, Color> colorOptions = {
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF4CAF50),
    'red': Color(0xFFF44336),
    'purple': Color(0xFF9C27B0),
    'orange': Color(0xFFFF9800),
    'pink': Color(0xFFE91E63),
    'teal': Color(0xFF009688),
    'indigo': Color(0xFF3F51B5),
  };

  Color get primaryColor => colorOptions[_selectedColor] ?? colorOptions['green']!;

  Future<void> loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _selectedColor = prefs.getString('primaryColor') ?? 'green';
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  Future<void> setPrimaryColor(String color) async {
    _selectedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primaryColor', color);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _isDarkMode = false;
    _selectedColor = 'green';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', false);
    await prefs.setString('primaryColor', 'green');
    notifyListeners();
  }

  ColorScheme getLightColorScheme() {
    return ColorScheme.fromSeed(seedColor: primaryColor);
  }

  ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
  }
}
