import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadFromStorage()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // انتخاب تم بر اساس themeMode
    final currentTheme = themeProvider.themeMode == ThemeMode.light
        ? themeProvider.lightThemeData
        : themeProvider.darkThemeData;

    // ── انیمیشن نرم برای تعویض تم (شماره ۱۷ درخواستی) ──
    return AnimatedTheme(
      data: currentTheme,
      duration: const Duration(milliseconds: 800),   // مدت زمان انیمیشن
      curve: Curves.easeInOut,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KAI AI',
        // ⚠️ برای پشتیبانی از ThemeMode.system (حالت خودکار) این دو خط را نگه میداریم
        theme: themeProvider.lightThemeData,
        darkTheme: themeProvider.darkThemeData,
        themeMode: themeProvider.themeMode,   // به ThemeProvider واگذار شده
        home: const SplashScreen(),
      ),
    );
  }
}