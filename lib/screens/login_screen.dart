import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/custom_page_route.dart';
import 'chat_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        CustomPageRoute(page: const ChatScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMsg = 'ورود ناموفق. ایمیل یا رمز عبور اشتباه است.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade700)),
                ),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ایمیل',
                  prefixIcon: FaIcon(FontAwesomeIcons.envelope),
                ),
                validator: (v) => (v != null && v.contains('@')) ? null : 'ایمیل معتبر وارد کنید',
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'رمز عبور',
                  prefixIcon: FaIcon(FontAwesomeIcons.lock),
                ),
                validator: (v) => (v != null && v.length >= 6) ? null : 'حداقل ۶ کاراکتر',
              ),
              const SizedBox(height: 30),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _login,
                      icon: const FaIcon(FontAwesomeIcons.rightToBracket),
                      label: const Text('ورود'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(context, CustomPageRoute(page: const RegisterScreen()));
                },
                child: const Text('حساب کاربری ندارید؟ ثبت‌نام کنید'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}