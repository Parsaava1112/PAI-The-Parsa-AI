import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import '../services/update_service.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';
import 'chat_screen.dart';
import '../widgets/parallax_background.dart';
import '../routes/custom_page_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _connectionFailed = false;

  @override
  void initState() {
    super.initState();
    _testConnectionAndProceed();
  }

  Future<void> _testConnectionAndProceed() async {
    try {
      final res = await ApiService.get('ping');
      if (res.statusCode == 200) {
        await Future.delayed(2.seconds);
        _checkUpdateThenNavigate();
      } else {
        _showRetry();
      }
    } catch (_) {
      _showRetry();
    }
  }

  void _showRetry() {
    setState(() => _connectionFailed = true);
  }

  void _retry() {
    setState(() => _connectionFailed = false);
    _testConnectionAndProceed();
  }

  Future<void> _checkUpdateThenNavigate() async {
    final updateData = await UpdateService.checkForUpdate();
    if (updateData != null && await UpdateService.isUpdateAvailable(updateData)) {
      if (mounted) {
        final result = await _showUpdateDialog(updateData);
        if (result == true) {
          final url = Platform.isAndroid
              ? updateData['download_url_android']
              : updateData['download_url_windows'];
          if (url != null && url.isNotEmpty) {
            await launchUrl(Uri.parse(url));
          }
          if (updateData['force_update'] == true) {
            SystemNavigator.pop();
            return;
          }
        }
      }
    }
    if (mounted) {
      final auth = context.read<AuthProvider>();
      Navigator.pushReplacement(
        context,
        CustomPageRoute(page: auth.isLoggedIn ? const ChatScreen() : const WelcomeScreen()),
      );
    }
  }

  Future<bool?> _showUpdateDialog(Map<String, dynamic> updateData) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !(updateData['force_update'] == true),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.circleArrowUp, color: Colors.orange),
            SizedBox(width: 10),
            Text('نسخه جدید'),
          ],
        ),
        content: Text('لطفاً برنامه را به نسخه ${updateData['version']} به‌روزرسانی کنید.'),
        actions: [
          if (!(updateData['force_update'] == true))
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('بعداً')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const FaIcon(FontAwesomeIcons.download, size: 18),
            label: const Text('دانلود'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _connectionFailed
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('ارتباط با سرور برقرار نشد'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            )
          : ParallaxBackground(
              imagePath: 'assets/images/galaxy_bg.png',
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ربات سه‌بعدی Lottie
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Lottie.asset('assets/lottie/robot_3d.json'),
                    ).animate().scale(duration: 1.seconds).fadeIn(),
                    const SizedBox(height: 20),
                    Text('KAI AI',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Vazir'))
                        .animate().fadeIn(delay: 0.5.seconds),
                  ],
                ),
              ),
            ),
    );
  }
}