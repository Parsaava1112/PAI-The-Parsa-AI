import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;
  const TypewriterText({super.key, required this.text, this.speed = const Duration(milliseconds: 50)});

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.speed * widget.text.length,
      vsync: this,
    );
    _charCount = IntTween(begin: 0, end: widget.text.length).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final String displayedText = widget.text.substring(0, _charCount.value);
        return Text(
          displayedText,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        );
      },
    );
  }
}