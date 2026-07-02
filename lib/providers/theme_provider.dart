import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// ─── حالت‌های تم سفارشی (برای ChatScreen و UI) ─────
enum AppThemeMode {
  light,
  dark,
  happy,
  nature,
  cyberpunk,
}

extension AppThemeModeExtension on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.light: return 'روشن';
      case AppThemeMode.dark: return 'تاریک';
      case AppThemeMode.happy: return 'شاد';
      case AppThemeMode.nature: return 'طبیعت';
      case AppThemeMode.cyberpunk: return 'سایبرپانک';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light: return Icons.wb_sunny;
      case AppThemeMode.dark: return Icons.nightlight_round;
      case AppThemeMode.happy: return Icons.emoji_emotions;
      case AppThemeMode.nature: return Icons.eco;
      case AppThemeMode.cyberpunk: return Icons.memory;
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _currentThemeName = 'light';   // نام ذخیره‌شده در SharedPreferences
  AppThemeMode _appThemeMode = AppThemeMode.light;
  String? _customBackgroundPath;
  bool _useDynamicBackground = false;

  // ═══════════ getterهای عمومی ═══════════
  ThemeMode get themeMode => _themeMode;
  String get currentThemeName => _currentThemeName;
  AppThemeMode get appThemeMode => _appThemeMode;   // برای ChatScreen
  String? get customBackgroundPath => _customBackgroundPath;
  bool get useDynamicBackground => _useDynamicBackground;

  // ── تم روشن بسته به نام ذخیره‌شده ─────
  ThemeData get lightThemeData {
    switch (_currentThemeName) {
      case 'shad': return _shadTheme();
      case 'classic': return _classicTheme();
      case 'happy': return _happyTheme();
      case 'nature': return _natureTheme();
      default: return _buildLightTheme();
    }
  }

  // ── تم تاریک (پیش‌فرض یا سایبرپانک) ──
  ThemeData get darkThemeData {
    if (_currentThemeName == 'cyberpunk') {
      return _cyberpunkTheme();
    }
    return _buildDarkTheme();
  }

  ThemeProvider() {
    _loadAll();
  }

  // ═══════════ تغییر تم (رشته‌ای) ═══════════
  Future<void> changeTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    switch (themeName) {
      case 'auto':
        _autoTheme();
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        _appThemeMode = AppThemeMode.dark;
        break;
      case 'shad':
      case 'classic':
        _themeMode = ThemeMode.light;
        _appThemeMode = AppThemeMode.light;   // این دو تم بر اساس lightThemeData تعریف شدن
        break;
      case 'happy':
        _themeMode = ThemeMode.light;
        _appThemeMode = AppThemeMode.happy;
        break;
      case 'nature':
        _themeMode = ThemeMode.light;
        _appThemeMode = AppThemeMode.nature;
        break;
      case 'cyberpunk':
        _themeMode = ThemeMode.dark;           // ⚡ اصلاح‌شده – باید dark باشه
        _appThemeMode = AppThemeMode.cyberpunk;
        break;
      default: // light
        _themeMode = ThemeMode.light;
        _appThemeMode = AppThemeMode.light;
    }
    _currentThemeName = themeName;
    await prefs.setString('theme', themeName);
    notifyListeners();
  }

  // تغییر مستقیم با AppThemeMode (مناسب برای دکمه‌ها)
  Future<void> setAppThemeMode(AppThemeMode mode) async {
    String name;
    switch (mode) {
      case AppThemeMode.light: name = 'light'; break;
      case AppThemeMode.dark: name = 'dark'; break;
      case AppThemeMode.happy: name = 'happy'; break;
      case AppThemeMode.nature: name = 'nature'; break;
      case AppThemeMode.cyberpunk: name = 'cyberpunk'; break;
    }
    await changeTheme(name);
  }

  // ─── حالت خودکار (بر اساس ساعت روز) ───
  void _autoTheme() {
    final hour = DateTime.now().hour;
    final isLight = (hour >= 6 && hour < 18);
    _themeMode = isLight ? ThemeMode.light : ThemeMode.dark;
    _appThemeMode = isLight ? AppThemeMode.light : AppThemeMode.dark;
    _currentThemeName = 'auto';
    // هر یک ساعت یک‌بار به‌روزرسانی
    Future.delayed(const Duration(hours: 1), () {
      if (_currentThemeName == 'auto') {
        _autoTheme();
        notifyListeners();
      }
    });
  }

  // ═══════════ مدیریت پس‌زمینه ═════════════
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
        if (data['image'] != null) {
          setBackground(data['image']);
        }
      }
    } catch (_) {}
  }

  // ─── بارگذاری تنظیمات ذخیره‌شده ────
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'light';
    await changeTheme(theme);
    _customBackgroundPath = prefs.getString('background_image');
    _useDynamicBackground = prefs.getBool('use_dynamic_background') ?? false;
    notifyListeners();
  }

  // ═══════════ تِم‌های اختصاصی ═══════════

  // تم روشن پایه
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: Colors.white,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // تم تاریک پایه
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      fontFamily: 'Vazir',
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // تم "شاد" (قبلاً shad)
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // تم "کلاسیک"
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // تم "شاد جدید" – Happy
  ThemeData _happyTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFFF6F91),
      scaffoldBackgroundColor: const Color(0xFFFFF4E6),
      fontFamily: 'Vazir',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3D2C2E)),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        color: Colors.white,
        shadowColor: const Color(0xFFFF6F91).withOpacity(0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6F91),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          elevation: 8,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF0F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.pink.shade200),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFF4E6),
        foregroundColor: Color(0xFF3D2C2E),
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF6F91),
      ),
    );
  }

  // تم طبیعت – Nature
  ThemeData _natureTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4CAF50),
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      fontFamily: 'Vazir',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2E3B2E)),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFFFDFFF0),
        shadowColor: Colors.green.withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.green.shade300),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF1F8E9),
        foregroundColor: Color(0xFF2E3B2E),
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  // تم سایبرپانک – Cyberpunk
  ThemeData _cyberpunkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00FFFF),
      scaffoldBackgroundColor: const Color(0xFF0D0221),
      fontFamily: 'Vazir',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFE0E0FF)),
        labelSmall: TextStyle(color: Color(0xFFB0B0FF)),
      ),
      cardTheme: CardThemeData(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        color: const Color(0xFF1A0B2E),
        shadowColor: const Color(0xFF00FFFF).withOpacity(0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FFFF),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A1A4A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 1),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9D4EDD)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0221),
        foregroundColor: Color(0xFF00FFFF),
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00FFFF),
        foregroundColor: Colors.black,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF00FFFF)),
    );
  }
}