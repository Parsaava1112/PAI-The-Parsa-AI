import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import '../widgets/typewriter_text.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool showFeedback;
  final String? feedback;
  final int? messageId;
  final String? conversationId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.showFeedback = false,
    this.feedback,
    this.messageId,
    this.conversationId,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((message) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _flutterTts.setLanguage("fa-IR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(widget.message);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('متن کپی شد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: widget.isUser
              ? Theme.of(context).primaryColor
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: widget.isUser ? const Radius.circular(0) : null,
            bottomLeft: widget.isUser ? null : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isUser
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(5, 5),
            ),
            BoxShadow(
              color: widget.isUser
                  ? Colors.black.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.isUser
                ? Text(widget.message, style: const TextStyle(color: Colors.white))
                : TypewriterText(text: widget.message),
            const SizedBox(height: 8),
            // ردیف دکمه‌های کمکی
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // دکمه کپی
                IconButton(
                  iconSize: 18,
                  icon: const FaIcon(FontAwesomeIcons.copy, size: 16),
                  onPressed: _copyToClipboard,
                  splashRadius: 18,
                ),
                const SizedBox(width: 4),
                // دکمه خواندن (تبدیل به موج صدا هنگام صحبت)
                IconButton(
                  iconSize: 18,
                  icon: _isSpeaking
                      ? Lottie.asset(
                          'assets/lottie/weather/sound_wave.json',
                          width: 24,
                          height: 24,
                        )
                      : const FaIcon(FontAwesomeIcons.volumeHigh, size: 16),
                  onPressed: _speak,
                  splashRadius: 18,
                ),
                // دکمه‌های فیدبک (فقط برای پیام هوش مصنوعی)
                if (widget.showFeedback && widget.messageId != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 18,
                    icon: FaIcon(
                      FontAwesomeIcons.thumbsUp,
                      color: widget.feedback == 'like'
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 16,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // اینجا کد ارسال فیدبک
                    },
                    splashRadius: 18,
                  ),
                  IconButton(
                    iconSize: 18,
                    icon: FaIcon(
                      FontAwesomeIcons.thumbsDown,
                      color: widget.feedback == 'dislike'
                          ? Colors.red
                          : Colors.grey,
                      size: 16,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // اینجا کد ارسال فیدبک
                    },
                    splashRadius: 18,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}