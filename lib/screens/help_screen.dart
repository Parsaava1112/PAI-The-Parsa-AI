import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('راهنما')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _faqItem(context, 'چگونه از مدل‌های مختلف استفاده کنم؟', 'در صفحه چت، مدل مورد نظر را از منوی بالا انتخاب کنید.'),
          _faqItem(context, 'آیا تاریخچه مکالمات ذخیره می‌شود؟', 'بله، تمام گفتگوها در بخش مکالمات قابل مشاهده هستند.'),
          _faqItem(context, 'چگونه تم برنامه را تغییر دهم؟', 'از منوی کناری به تنظیمات بروید و تم دلخواه را انتخاب کنید.'),
        ],
      ),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      leading: const FaIcon(FontAwesomeIcons.circleQuestion, size: 20),
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [Padding(padding: const EdgeInsets.all(16), child: Text(answer))],
    );
  }
}