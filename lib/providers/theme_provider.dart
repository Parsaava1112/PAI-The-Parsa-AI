import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _currentThemeName = 'light'; // light, dark, shad, classic, auto
  String? _customBackgroundPath;
  bool _useDynamicBackground = false;

  ThemeMode get themeMode => _themeMode;
  String get currentThemeName => _currentThemeName;
  String? get customBackgroundPath => _customBackgroundPath;
  bool get useDynamicBackground => _useDynamicBackground;

  ThemeData get lightThemeData {
    if (_currentThemeName == 'shad') return _shadTheme();
    if (_currentThemeName == 'classic') return _classicTheme();
    return _buildLightTheme();
  }

  ThemeData get darkThemeData => _buildDarkTheme();

  ThemeProvider() {
    _loadAll();
  }

  Future<void> changeTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    switch (themeName) {
      case 'auto':
        _autoTheme();
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'shad':
      case 'classic':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.light;
    }
    _currentThemeName = themeName;
    await prefs.setString('theme', themeName);
    notifyListeners();
  }

  void _autoTheme() {
    final hour = DateTime.now().hour;
    _themeMode = (hour >= 6 && hour < 18) ? ThemeMode.light : ThemeMode.dark;
    // هر یک ساعت یک‌بار به‌روزرسانی شود (در صورت فعال بودن auto)
    Future.delayed(const Duration(hours: 1), () {
      if (_currentThemeName == 'auto') {
        _autoTheme();
        notifyListeners();
      }
    });
  }

  Future<void> setBackground(String? path) async {
    _customBackgroundPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('background_image', path);
    } else {
      await prefs.remove('background_image');
    }
    notifyListeners();
  }

  Future<void> setDynamicBackground(bool value) async {
    _useDynamicBackground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_dynamic_background', value);
    notifyListeners();
  }

  Future<void> generateThemeFromAI(String description) async {
    try {
      final res = await ApiService.post('theme/generate', {'description': description});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // فرض می‌کنیم پاسخ شامل primary, background, image باشد
        // می‌توانی اینجا تم را تغییر دهی یا تصویر پس‌زمینه را تنظیم کنی
        if (data['image'] != null) {
          setBackground(data['image']);
        }
        // اینجا می‌توانی primary color را هم تنظیم کنی (نیاز به بازنویسی ThemeData دارد)
      }
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'light';
    changeTheme(theme);
    _customBackgroundPath = prefs.getString('background_image');
    _useDynamicBackground = prefs.getBool('use_dynamic_background') ?? false;
    notifyListeners();
  }

  // ---------- تم‌های پایه ----------
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: Colors.white,
      cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  ThemeData _shadTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.orange,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Vazir',
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        shadowColor: Colors.orange.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.orange.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  ThemeData _classicTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.brown,
      scaffoldBackgroundColor: const Color(0xFFF5F0E8),
      fontFamily: 'Vazir',
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFFFDFBF7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.brown.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}