import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import '../widgets/parallax_background.dart';
import '../routes/custom_page_route.dart';
import 'login_screen.dart';
import 'register_screen.dart'; // فقط RegisterScreen را export می‌کند

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    return Scaffold(
      body: ParallaxBackground(
        imagePath: 'assets/images/galaxy_bg.png',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Lottie.asset('assets/lottie/robot_3d.json'),
                ),
                const SizedBox(height: 20),
                Text('به PAI خوش آمدید',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('دستیار هوش مصنوعی چندمنظوره\nپزشکی، زبان، متن و بیشتر...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[900])),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, CustomPageRoute(page: const LoginScreen()));
                    },
                    icon: const FaIcon(FontAwesomeIcons.rightToBracket),
                    label: const Text('ورود'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, CustomPageRoute(page: const RegisterScreen()));
                    },
                    icon: const FaIcon(FontAwesomeIcons.userPlus),
                    label: const Text('ثبت‌نام'),
                    style: outlinedButtonStyle,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}