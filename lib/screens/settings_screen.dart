import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // اضافه کردن برای اطمینان (هر چند با material در دسترس است)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

// مدیریت ساده‌ی زبان
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fa');
  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Map<String, String>> _backgroundOptions = [
    {'path': 'assets/images/backgrounds/galaxy_bg.png', 'label': 'کهکشان'},
    {'path': 'assets/images/backgrounds/nature1.png', 'label': 'طبیعت ۱'},
    {'path': 'assets/images/backgrounds/nature2.png', 'label': 'طبیعت ۲'},
  ];

  final PageController _bgPageController = PageController(viewportFraction: 0.35);
  final ImagePicker _imagePicker = ImagePicker();

  late SharedPreferences _prefs;
  bool _incognitoMode = false;
  double _chatFontSize = 16.0;
  double _chatLineHeight = 1.5;
  String _chatFontFamily = 'Vazir';
  Color _accentColor = Colors.blue;
  final List<String> _fontFamilies = ['Vazir', 'Sahel', 'Shabnam', 'IranSans'];

  List _aiModels = [];
  String? _selectedModelId;
  bool _modelsLoading = true;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _fetchAIModels();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _incognitoMode = _prefs.getBool('incognito') ?? false;
      _chatFontSize = _prefs.getDouble('chat_font_size') ?? 16.0;
      _chatLineHeight = _prefs.getDouble('chat_line_height') ?? 1.5;
      _chatFontFamily = _prefs.getString('chat_font_family') ?? 'Vazir';
      final int? accentColorValue = _prefs.getInt('accent_color');
      _accentColor = accentColorValue != null ? Color(accentColorValue) : Colors.blue;
    });
  }

  Future<void> _fetchAIModels() async {
    try {
      final response = await ApiService.get('models');
      final List models = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _aiModels = models;
          _selectedModelId = models.isNotEmpty ? models.first['id'] : null;
          _modelsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _modelsLoading = false);
        debugPrint('Error fetching AI models: $e');
      }
    }
  }

  @override
  void dispose() {
    _bgPageController.dispose();
    super.dispose();
  }
  Future<void> _saveIncognito(bool val) async {
    setState(() => _incognitoMode = val);
    await _prefs.setBool('incognito', val);
  }

  Future<void> _saveFontSize(double val) async {
    setState(() => _chatFontSize = val);
    await _prefs.setDouble('chat_font_size', val);
  }

  Future<void> _saveLineHeight(double val) async {
    setState(() => _chatLineHeight = val);
    await _prefs.setDouble('chat_line_height', val);
  }

  Future<void> _saveFontFamily(String val) async {
    setState(() => _chatFontFamily = val);
    await _prefs.setString('chat_font_family', val);
  }

  Future<void> _saveAccentColor(Color color) async {
    setState(() => _accentColor = color);
    await _prefs.setInt('accent_color', color.value);
  }

  Future<void> _createThemeFromImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(image.path)),
        size: const Size(200, 200),
        maximumColorCount: 5,
      );
      final dominantColor = palette.dominantColor?.color ?? Colors.blue;
      _saveAccentColor(dominantColor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('رنگ اصلی از عکس استخراج شد: ${dominantColor.toString()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در استخراج رنگ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final authProv = context.watch<AuthProvider>();
    final localeProv = context.watch<LocaleProvider>();

    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // هدر جمع‌شونده
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor.withOpacity(0.8), _accentColor.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
          // هدر ساده بدون گرادینت پیچیده
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _accentColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    CircleAvatar(
                      radius: 45,
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Text(
                        authProv.user != null && authProv.user!['name'] != null
                            ? authProv.user!['name'][0].toUpperCase()
                            : '👤',
                        style: const TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                        style: const TextStyle(fontSize: 28, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProv.user?['name'] ?? 'کاربر مهمان',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      authProv.user?['email'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: _accentColor,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // پیش‌نمایش چت
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('👁️ پیش‌نمایش چت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        _ChatPreview(
                          accentColor: _accentColor,
                          fontSize: _chatFontSize,
                          fontFamily: _chatFontFamily,
                          lineHeight: _chatLineHeight,
                          bubbleColor: Theme.of(context).colorScheme.primary,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                  // انتخاب تم
                  _buildSimpleCard(
                    title: '🎨 انتخاب تم',
                    child: Column(
                      children: [
                        _ThemeRadioTile('روشن', 'light', themeProv),
                        _ThemeRadioTile('تاریک', 'dark', themeProv),
                        _ThemeRadioTile('شاد (پاستلی)', 'shad', themeProv),
                        _ThemeRadioTile('کلاسیک', 'classic', themeProv),
                        RadioListTile<String>(
                          title: const Text('خودکار (بر اساس ساعت)'),
                          value: 'auto',
                          groupValue: themeProv.currentThemeName,
                          onChanged: (v) => themeProv.changeTheme(v!),
                          activeColor: _accentColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // انتخاب تم
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🎨 انتخاب تم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        _ThemeRadioTile('روشن', 'light', themeProv),
                        _ThemeRadioTile('تاریک', 'dark', themeProv),
                        _ThemeRadioTile('شاد (پاستلی)', 'shad', themeProv),
                        _ThemeRadioTile('کلاسیک', 'classic', themeProv),
                        RadioListTile<String>(
                          title: const Text('خودکار (بر اساس ساعت)'),
                          value: 'auto',
                          groupValue: themeProv.currentThemeName,
                          onChanged: (v) {
                            themeProv.changeTheme(v!);
                          },
                          activeColor: _accentColor,
                  // رنگ اکسنت
                  _buildSimpleCard(
                    title: '🌈 رنگ اصلی (Accent)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                              Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                              Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                              Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                            ].map((color) => _ColorCircle(
                              color: color,
                              isSelected: _accentColor.value == color.value,
                              onTap: () => _saveAccentColor(color),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('ساخت تم از عکس'),
                          onPressed: _createThemeFromImage,
                          style: OutlinedButton.styleFrom(foregroundColor: _accentColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // رنگ اکسنت
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🌈 رنگ اصلی (Accent)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                              Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                              Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                              Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                            ].map((color) => _ColorCircle(
                              color: color,
                              isSelected: _accentColor.value == color.value,
                              onTap: () => _saveAccentColor(color),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('ساخت تم از عکس'),
                          onPressed: _createThemeFromImage,
                          style: OutlinedButton.styleFrom(foregroundColor: _accentColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // پس‌زمینه چت
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🖼️ پس‌زمینه چت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('پویا (آب‌وهوا)'),
                          value: themeProv.useDynamicBackground,
                          onChanged: (val) {
                            themeProv.setDynamicBackground(val);
                            if (val && themeProv.customBackgroundPath != null) {
                              themeProv.setBackground(null);
                            }
                          },
                          activeColor: _accentColor,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: PageView.builder(
                            controller: _bgPageController,
                            itemCount: _backgroundOptions.length + 1,
                            itemBuilder: (context, index) {
                              final isDefault = index == 0;
                              final String? path = isDefault ? null : _backgroundOptions[index - 1]['path'];
                              final String label = isDefault ? 'پیش‌فرض' : _backgroundOptions[index - 1]['label']!;
                              final isSelected = isDefault
                                  ? themeProv.customBackgroundPath == null
                                  : themeProv.customBackgroundPath == path;
                              return _BgCarouselItem(
                                path: path,
                                label: label,
                                isSelected: isSelected,
                                onTap: () {
                                  themeProv.setBackground(path);
                                  if (path != null && themeProv.useDynamicBackground) {
                                    themeProv.setDynamicBackground(false);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // مدل هوش مصنوعی
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🤖 مدل پیش‌فرض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 10),
                        if (_modelsLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_aiModels.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('مدلی یافت نشد', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedModelId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                  ),
                                  items: _aiModels.map<DropdownMenuItem<String>>((m) {
                                    return DropdownMenuItem<String>(
                                      value: m['id'] as String,
                                      child: Text(m['name'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (val) async {
                                    setState(() => _selectedModelId = val);
                                    await ApiService.put('settings', {'ai_model': val});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.speed),
                                tooltip: 'تست سرعت',
                                onPressed: _testModelSpeed,
                                color: _accentColor,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // تایپوگرافی
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✍️ اندازه و فونت پیام‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('اندازه فونت:'),
                            Expanded(
                              child: Slider(
                                value: _chatFontSize,
                                min: 12,
                                max: 24,
                                divisions: 12,
                                label: _chatFontSize.round().toString(),
                                activeColor: _accentColor,
                                onChanged: _saveFontSize,
                              ),
                            ),
                            Text(_chatFontSize.toStringAsFixed(0)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('فاصله خطوط:'),
                            Expanded(
                              child: Slider(
                                value: _chatLineHeight,
                                min: 1.0,
                                max: 2.5,
                                divisions: 6,
                                label: _chatLineHeight.toStringAsFixed(1),
                                activeColor: _accentColor,
                                onChanged: _saveLineHeight,
                              ),
                            ),
                            Text(_chatLineHeight.toStringAsFixed(1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _chatFontFamily,
                          decoration: InputDecoration(
                            labelText: 'فونت',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                          ),
                          items: _fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (val) => _saveFontFamily(val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // سایر تنظیمات
                  _buildGlassCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('🕶️ حالت ناشناس (Incognito)'),
                          subtitle: const Text('تاریخچه چت ذخیره نمی‌شود'),
                          value: _incognitoMode,
                          onChanged: _saveIncognito,
                          activeColor: _accentColor,
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('🌐 زبان برنامه'),
                          trailing: DropdownButton<Locale>(
                            value: localeProv.locale,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: Locale('fa'), child: Text('فارسی')),
                              DropdownMenuItem(value: Locale('en'), child: Text('English')),
                            ],
                            onChanged: (loc) {
                              if (loc != null) {
                                localeProv.setLocale(loc);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // حساب کاربری و خروج
                  _buildGlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('خروج از حساب', style: TextStyle(color: Colors.red)),
                          onTap: () => _showLogoutDialog(context, authProv),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

                  // پس‌زمینه چت (نسخه ساده‌شده)
                  _buildSimpleCard(
                    title: '🖼️ پس‌زمینه چت',
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('پویا (آب‌وهوا)'),
                          value: themeProv.useDynamicBackground,
                          onChanged: (val) {
                            themeProv.setDynamicBackground(val);
                            if (val && themeProv.customBackgroundPath != null) {
                              themeProv.setBackground(null);
                            }
                          },
                          activeColor: _accentColor,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _backgroundOptions.length + 1,
                            itemBuilder: (context, index) {
                              final isDefault = index == 0;
                              final String? path = isDefault ? null : _backgroundOptions[index - 1]['path'];
                              final String label = isDefault ? 'پیش‌فرض' : _backgroundOptions[index - 1]['label']!;
                              final isSelected = isDefault
                                  ? themeProv.customBackgroundPath == null
                                  : themeProv.customBackgroundPath == path;
                              return GestureDetector(
                                onTap: () {
                                  themeProv.setBackground(path);
                                  if (path != null && themeProv.useDynamicBackground) {
                                    themeProv.setDynamicBackground(false);
                                  }
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: path == null ? Colors.grey[300] : null,
                                    image: path != null
                                        ? DecorationImage(image: AssetImage(path), fit: BoxFit.cover)
                                        : null,
                                    border: Border.all(
                                      color: isSelected ? _accentColor : Colors.grey,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: path == null
                                      ? const Text('بدون\nتصویر', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // مدل هوش مصنوعی
                  _buildSimpleCard(
                    title: '🤖 مدل پیش‌فرض',
                    child: _modelsLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _aiModels.isEmpty
                            ? const Text('مدلی یافت نشد')
                            : DropdownButtonFormField<String>(
                                value: _selectedModelId,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                items: _aiModels.map<DropdownMenuItem<String>>((m) {
                                  return DropdownMenuItem<String>(
                                    value: m['id'],
                                    child: Text(m['name']),
                                  );
                                }).toList(),
                                onChanged: (val) async {
                                  setState(() => _selectedModelId = val);
                                  await ApiService.put('settings', {'ai_model': val});
                                },
                              ),
                  ),
                  const SizedBox(height: 16),

                  // تایپوگرافی
                  _buildSimpleCard(
                    title: '✍️ اندازه و فونت پیام‌ها',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('اندازه فونت:'),
                            Expanded(
                              child: Slider(
                                value: _chatFontSize,
                                min: 12,
                                max: 24,
                                divisions: 12,
                                label: _chatFontSize.round().toString(),
                                activeColor: _accentColor,
                                onChanged: _saveFontSize,
                              ),
                            ),
                            Text(_chatFontSize.toStringAsFixed(0)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('فاصله خطوط:'),
                            Expanded(
                              child: Slider(
                                value: _chatLineHeight,
                                min: 1.0,
                                max: 2.5,
                                divisions: 6,
                                label: _chatLineHeight.toStringAsFixed(1),
                                activeColor: _accentColor,
                                onChanged: _saveLineHeight,
                              ),
                            ),
                            Text(_chatLineHeight.toStringAsFixed(1)),
                          ],
                        ),
                        DropdownButtonFormField<String>(
                          value: _chatFontFamily,
                          decoration: InputDecoration(
                            labelText: 'فونت',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          items: _fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (val) => _saveFontFamily(val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // سایر تنظیمات
                  _buildSimpleCard(
                    title: 'سایر',
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('🕶️ حالت ناشناس'),
                          subtitle: const Text('تاریخچه ذخیره نمی‌شود'),
                          value: _incognitoMode,
                          onChanged: _saveIncognito,
                          activeColor: _accentColor,
                        ),
                        ListTile(
                          title: const Text('🌐 زبان برنامه'),
                          trailing: DropdownButton<Locale>(
                            value: localeProv.locale,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: Locale('fa'), child: Text('فارسی')),
                              DropdownMenuItem(value: Locale('en'), child: Text('English')),
                            ],
                            onChanged: (loc) {
                              if (loc != null) localeProv.setLocale(loc);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // خروج
                  _buildSimpleCard(
                    title: 'حساب',
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('خروج از حساب', style: TextStyle(color: Colors.red)),
                      onTap: () => _showLogoutDialog(context, authProv),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // کارت ساده بدون هیچ پس‌زمینه شیشه‌ای
  Widget _buildSimpleCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _ThemeRadioTile(String title, String value, ThemeProvider themeProv) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: themeProv.currentThemeName,
      onChanged: (v) => themeProv.changeTheme(v!),
      activeColor: _accentColor,
    );
  }

  Widget _ColorCircle({required Color color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : [],
          ),
        ),
      ),
    );
  }

  void _testModelSpeed() async {
    // ... (بدون تغییر) ...
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('آیا مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              authProv.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor.withOpacity(0.6), // میزان کدری
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white24),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: child,
  );
}

  Widget _ThemeRadioTile(String title, String value, ThemeProvider themeProv) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: themeProv.currentThemeName,
      onChanged: (v) {
        themeProv.changeTheme(v!);
      },
      activeColor: _accentColor,
    );
  }

  Widget _ColorCircle({required Color color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : [],
          ),
        ),
      ),
    );
  }

  void _testModelSpeed() async {
    if (_selectedModelId == null) return;
    final stopwatch = Stopwatch()..start();
    try {
      final response = await ApiService.post('test_model', {'model': _selectedModelId});
      stopwatch.stop();
      if (mounted) {
        final ms = stopwatch.elapsedMilliseconds;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('سرعت پاسخگویی'),
            content: Text('مدل $_selectedModelId در $ms میلی‌ثانیه پاسخ داد.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('خطا'),
            content: Text('تست ناموفق: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProv) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeInOutBack);
        return ScaleTransition(
          scale: curved,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red),
                SizedBox(width: 10),
                Text('خروج از حساب'),
              ],
            ),
            content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  authProv.logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                },
                child: const Text('خروج', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// پیش‌نمایش چت
class _ChatPreview extends StatelessWidget {
  final Color accentColor;
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final Color bubbleColor;
  final bool isDark;

  const _ChatPreview({
    required this.accentColor,
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.bubbleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[850] ?? Colors.grey, Colors.grey[900] ?? Colors.grey] // ✅ رفع null assertion
              : [Colors.grey[100]!, Colors.white],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                'سلام! حالت چطوره؟',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  height: lineHeight,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                'خوبم، مرسی!',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  height: lineHeight,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// آیتم کاروسل پس‌زمینه
class _BgCarouselItem extends StatelessWidget {
  final String? path;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BgCarouselItem({
    required this.path,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? bgPath = path;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgPath == null ? Colors.grey[300] : null,
          image: bgPath != null ? DecorationImage(image: AssetImage(bgPath), fit: BoxFit.cover) : null,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8)]
              : [],
        ),
        child: bgPath == null
            ? const Center(child: Text('بدون\nتصویر', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)))
            : null,
      ),
    );
  }
}