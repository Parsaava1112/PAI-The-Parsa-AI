import 'package:flutter/material.dart';

class ParallaxBackground extends StatefulWidget {
  final Widget child;
  final String imagePath; // تصویر پس‌زمینه (مثلاً galaxy)
  const ParallaxBackground({required this.child, required this.imagePath, super.key});

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        setState(() {
          _offset = Offset(
            (event.position.dx / MediaQuery.of(context).size.width - 0.5) * 20,
            (event.position.dy / MediaQuery.of(context).size.height - 0.5) * 20,
          );
        });
      },
      child: Stack(
        children: [
          Transform.translate(
            offset: _offset,
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}