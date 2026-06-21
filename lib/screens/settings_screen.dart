import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // لیست تصاویر پس‌زمینهٔ موجود در assets
  final List<Map<String, String>> _backgroundOptions = [
    {'path': 'assets/images/backgrounds/galaxy_bg.png', 'label': 'کهکشان'},
    {'path': 'assets/images/backgrounds/nature1.png', 'label': 'طبیعت'},
    {'path': 'assets/images/backgrounds/nature2.png', 'label': 'طبیعت'},
    // مسیرهای دیگری که اضافه کرده‌اید
  ];

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ══════════ ظاهر ══════════
          const Text('🎨 تم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<String>(
            title: const Text('روشن'),
            value: 'light',
            groupValue: themeProv.currentThemeName,
            onChanged: (v) => themeProv.changeTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('تاریک'),
            value: 'dark',
            groupValue: themeProv.currentThemeName,
            onChanged: (v) => themeProv.changeTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('شاد (پاستلی)'),
            value: 'shad',
            groupValue: themeProv.currentThemeName,
            onChanged: (v) => themeProv.changeTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('کلاسیک'),
            value: 'classic',
            groupValue: themeProv.currentThemeName,
            onChanged: (v) => themeProv.changeTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('خودکار (بر اساس ساعت)'),
            value: 'auto',
            groupValue: themeProv.currentThemeName,
            onChanged: (v) => themeProv.changeTheme(v!),
          ),

          const Divider(),

          // ══════════ پس‌زمینه چت ══════════
          const Text('🖼️ پس‌زمینه چت',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('پویا (بر اساس آب‌وهوا)'),
            subtitle: const Text('باران، برف، طوفان و...'),
            value: themeProv.useDynamicBackground,
            onChanged: (val) {
              themeProv.setDynamicBackground(val);
              // اگر پویا فعال شد، تصویر ثابت را غیرفعال کن
              if (val && themeProv.customBackgroundPath != null) {
                themeProv.setBackground(null);
              }
            },
          ),
          const SizedBox(height: 10),
          const Text('تصویر ثابت:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // گزینهٔ پیش‌فرض (بدون تصویر)
              _backgroundThumbnail(
                context,
                path: null,
                label: 'پیش‌فرض',
                isSelected: themeProv.customBackgroundPath == null,
              ),
              // تصاویر موجود
              for (final option in _backgroundOptions)
                _backgroundThumbnail(
                  context,
                  path: option['path']!,
                  label: option['label']!,
                  isSelected: themeProv.customBackgroundPath == option['path'],
                ),
            ],
          ),

          const Divider(),

          // ══════════ مدل پیش‌فرض ══════════
          const Text('🤖 هوش مصنوعی پیش‌فرض',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          FutureBuilder<http.Response>(
            future: ApiService.get('models'),
            builder: (ctx, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final models = jsonDecode(snap.data!.body) as List;
              return DropdownButtonFormField<String>(
                items: models.map<DropdownMenuItem<String>>((m) {
                  return DropdownMenuItem<String>(
                    value: m['id'] as String,
                    child: Text(m['name'] as String),
                  );
                }).toList(),
                onChanged: (val) async {
                  await ApiService.put('settings', {'ai_model': val});
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // ══════════ خروج ══════════
          OutlinedButton.icon(
            onPressed: () {
              authProv.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
            label: const Text('خروج از حساب'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundThumbnail(
    BuildContext context, {
    required String? path,
    required String label,
    required bool isSelected,
  }) {
    final themeProv = context.read<ThemeProvider>();
    return GestureDetector(
      onTap: () {
        themeProv.setBackground(path);
        // اگر تصویر ثابت انتخاب شد، پس‌زمینهٔ پویا را غیرفعال کن
        if (path != null && themeProv.useDynamicBackground) {
          themeProv.setDynamicBackground(false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: path == null ? Colors.grey[300] : null,
              image: path != null
                  ? DecorationImage(
                      image: AssetImage(path),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade400,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: path == null
                ? const Center(
                    child: Text('بدون\nتصویر',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12)))
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}