import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/custom_page_route.dart';
import 'chat_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _usernameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      // ورود موفق – برو به صفحه چت
      Navigator.pushAndRemoveUntil(
        context,
        CustomPageRoute(page: const ChatScreen()),
        (route) => false,
      );
    } else {
      // پیام خطا
      setState(() => _errorMsg = 'ثبت‌نام ناموفق. لطفاً دوباره تلاش کنید.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت‌نام')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // پیام خطا
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
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'نام کاربری',
                  prefixIcon: FaIcon(FontAwesomeIcons.user),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'نام کاربری الزامی است' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ایمیل',
                  prefixIcon: FaIcon(FontAwesomeIcons.envelope),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'ایمیل الزامی است';
                  if (!v.contains('@') || !v.contains('.')) return 'ایمیل معتبر نیست';
                  return null;
                },
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تکرار رمز عبور',
                  prefixIcon: FaIcon(FontAwesomeIcons.lock),
                ),
                validator: (v) => v == _passCtrl.text ? null : 'رمز عبور مطابقت ندارد',
              ),
              const SizedBox(height: 30),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _register,
                      icon: const FaIcon(FontAwesomeIcons.userPlus),
                      label: const Text('ثبت‌نام'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حساب کاربری دارید؟ وارد شوید'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}