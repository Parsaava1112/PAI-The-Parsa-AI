import 'dart:async';
import 'dart:ui'; // <-- برای ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:sensors_plus/sensors_plus.dart'; // <-- این شامل gyroEvents می‌شود
import 'package:shimmer/shimmer.dart';
import '../routes/custom_page_route.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // کنترلر انیمیشن شناور ربات
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // کنترلر انیمیشن متن‌ها
  late AnimationController _textController;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  // داده‌های ژیروسکوپ
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  StreamSubscription? _gyroSubscription;

  @override
  void initState() {
    super.initState();

    // --- ۱. شناور شدن ربات ---
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // --- ۴. انیمیشن آبشاری متن‌ها ---
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // شروع انیمیشن متن‌ها با کمی تأخیر
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _textController.forward();
    });

    // --- ۶. ژیروسکوپ (واکنش به حرکت دستگاه) ---
    // در نسخه‌های جدید sensors_plus از gyroEvents استفاده می‌کنیم
    _gyroSubscription = gyroEvents.listen((GyroscopeEvent event) {
      setState(() {
        // محدود کردن دامنه حرکت و نرم‌سازی
        _gyroX = event.x.clamp(-0.5, 0.5);
        _gyroY = event.y.clamp(-0.5, 0.5);
      });
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _textController.dispose();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- ۷. پس‌زمینهٔ پارالاکس چندلایه ---
          Positioned.fill(child: _buildParallaxBackground()),

          // محتوای اصلی
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ربات با انیمیشن شناور + تأثیر ژیروسکوپ
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        _gyroY * 10, // حرکت افقی با ژیروسکوپ
                        _floatAnimation.value + _gyroX * 10, // عمودی
                      ),
                      child: child,
                    ),
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Lottie.asset('assets/lottie/robot_3d.json'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // متن خوش‌آمدگویی با انیمیشن آبشاری
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Text(
                        'به Parsa AI خوش آمدید',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // زیرنویس با تأخیر بیشتر
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _textController,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                        ),
                      ),
                      child: Text(
                        'دستیار هوش مصنوعی چندمنظوره\nپزشکی، زبان، متن و بیشتر...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // --- ۵. دکمهٔ ورود شیشه‌ای با افکت شاین ---
                  _buildShimmerGlassButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        CustomPageRoute(page: const LoginScreen()),
                      );
                    },
                    icon: FontAwesomeIcons.rightToBracket,
                    label: 'ورود',
                    isElevated: true,
                  ),

                  const SizedBox(height: 12),

                  // دکمهٔ ثبت‌نام شیشه‌ای با افکت شاین
                  _buildShimmerGlassButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        CustomPageRoute(page: const RegisterScreen()),
                      );
                    },
                    icon: FontAwesomeIcons.userPlus,
                    label: 'ثبت‌نام',
                    isElevated: false,
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ساخت پس‌زمینهٔ پارالاکس چندلایه ---
  Widget _buildParallaxBackground() {
    // ضرایب سرعت حرکت لایه‌ها بر اساس ژیروسکوپ
    const double farLayerSpeed = 5.0;
    const double midLayerSpeed = 10.0;
    const double nearLayerSpeed = 18.0;

    return Stack(
      children: [
        // لایهٔ دور
        Transform.translate(
          offset: Offset(_gyroY * farLayerSpeed, _gyroX * farLayerSpeed),
          child: Image.asset(
            'assets/images/galaxy_bg_far.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // لایهٔ میانی
        Transform.translate(
          offset: Offset(_gyroY * midLayerSpeed, _gyroX * midLayerSpeed),
          child: Image.asset(
            'assets/images/galaxy_bg_mid.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // لایهٔ نزدیک
        Transform.translate(
          offset: Offset(_gyroY * nearLayerSpeed, _gyroX * nearLayerSpeed),
          child: Image.asset(
            'assets/images/galaxy_bg_near.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // overlay تیره برای خوانایی بهتر متن‌ها (اختیاری)
        Container(color: Colors.black.withOpacity(0.15)),
      ],
    );
  }

  // --- ساخت دکمهٔ شیشه‌ای با افکت شاین ---
  Widget _buildShimmerGlassButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isElevated,
  }) {
    final button = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // حالا ImageFilter قابل شناسایی است
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      icon,
                      color: isElevated ? Colors.white : Colors.deepPurple,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isElevated ? Colors.white : Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // بسته‌بندی با Shimmer برای افکت شاین متحرک
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.8),
      highlightColor: Colors.white.withOpacity(0.3),
      period: const Duration(seconds: 2),
      child: button,
    );
  }
}
