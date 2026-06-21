import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;
  const ParticleBackground({super.key, required this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with TickerProviderStateMixin {
  final List<_Particle> _particles = [];
  late AnimationController _controller;
  Offset _mouseOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    // ایجاد ۵۰ ذره تصادفی
    final rand = Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        x: rand.nextDouble() * 1.0, // نسبت عرض
        y: rand.nextDouble() * 1.0, // نسبت ارتفاع
        radius: rand.nextDouble() * 3 + 1,
        speed: rand.nextDouble() * 0.5 + 0.1,
        color: Colors.white.withOpacity(rand.nextDouble() * 0.3 + 0.1),
      ));
    }
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(event.position);
    setState(() {
      _mouseOffset = local;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _onPointerMove,
      child: CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          time: _controller.value,
          mouseOffset: _mouseOffset,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Particle {
  double x, y;
  double radius;
  double speed;
  Color color;
  _Particle({required this.x, required this.y, required this.radius, required this.speed, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Offset mouseOffset;
  _ParticlePainter({required this.particles, required this.time, required this.mouseOffset});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // حرکت آرام به سمت پایین
      double newY = (p.y + p.speed * 0.001) % 1.0;
      p.y = newY;
      // تأثیر نرم موس
      double dx = (mouseOffset.dx / size.width - 0.5) * 5;
      double dy = (mouseOffset.dy / size.height - 0.5) * 5;
      Offset pos = Offset((p.x * size.width + dx), (p.y * size.height + dy));
      final paint = Paint()..color = p.color;
      canvas.drawCircle(pos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}