import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/conversations_screen.dart';
import '../screens/help_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/welcome_screen.dart';
import '../routes/custom_page_route.dart';
import 'dart:ui';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Drawer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(radius: 30, backgroundImage: const AssetImage('assets/icon/app_icon.png')),
                      const SizedBox(height: 10),
                      Text(user?['username'] ?? 'کاربر', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user?['email'] ?? '', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                _drawerItem(context, FontAwesomeIcons.message, 'مکالمات', () {
                  Navigator.push(context, CustomPageRoute(page: const ConversationsScreen()));
                }),
                _drawerItem(context, FontAwesomeIcons.circleQuestion, 'راهنما', () {
                  Navigator.push(context, CustomPageRoute(page: const HelpScreen()));
                }),
                _drawerItem(context, FontAwesomeIcons.user, 'پروفایل', () {
                  Navigator.push(context, CustomPageRoute(page: const ProfileScreen()));
                }),
                _drawerItem(context, FontAwesomeIcons.gear, 'تنظیمات', () {
                  Navigator.push(context, CustomPageRoute(page: const SettingsScreen()));
                }),
                const Divider(),
                _drawerItem(context, FontAwesomeIcons.rightFromBracket, 'خروج', () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(context, CustomPageRoute(page: const WelcomeScreen()), (route) => false);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: FaIcon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}