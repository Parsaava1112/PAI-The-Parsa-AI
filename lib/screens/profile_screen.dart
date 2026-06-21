import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 50, backgroundColor: Theme.of(context).primaryColor, child: const FaIcon(FontAwesomeIcons.user, size: 40, color: Colors.white)),
            const SizedBox(height: 20),
            Text(user?['username'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
            Text(user?['email'] ?? '', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}