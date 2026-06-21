import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WeatherBackground extends StatelessWidget {
  final Map<String, dynamic>? weatherData; // شامل 'condition' و 'isDay'
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.child,
    this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) return child;

    final condition = weatherData!['condition'] as String?;
    final isDay = weatherData!['isDay'] as bool? ?? true;

    // انتخاب انیمیشن مناسب
    String? lottieAsset;
    switch (condition) {
      case 'Rain':
      case 'Drizzle':
        lottieAsset = 'assets/lottie/weather/rain.json';
        break;
      case 'Thunderstorm':
        lottieAsset = 'assets/lottie/weather/thunderstorm.json';
        break;
      case 'Clear':
        lottieAsset = isDay
            ? 'assets/lottie/weather/sunny.json'
            : 'assets/lottie/weather/night.json';
        break;
      case 'Clouds':
        // ابری کامل یا نیمه‌ابری بر اساس میزان ابر (اختیاری)
        // ساده: اگر "few clouds" یا "scattered" بود نیمه‌ابری، در غیر این صورت ابری
        // چون API اصلی را نداریم، می‌توان از توضیحات استفاده کرد.
        // برای سادگی: اگر ابری کامل (overcast clouds) یا "broken" ابری، بقیه نیمه‌ابری
        // فعلاً اینجا شرط ساده می‌گذاریم: همیشه cloudy
        lottieAsset = 'assets/lottie/weather/cloudy.json';
        // برای دقیق‌تر شدن نیاز به description داریم که در weatherData اضافه کنیم
        break;
      case 'Snow':
        lottieAsset = 'assets/lottie/weather/snow.json';
        break;
      default:
        return child;
    }

    // اگر انیمیشنی موجود نبود، فقط child را برگردان
    if (lottieAsset == null) return child;

    return Stack(
      children: [
        Positioned.fill(
          child: Lottie.asset(
            lottieAsset,
            fit: BoxFit.cover,
            repeat: true,
            animate: true,
          ),
        ),
        child,
      ],
    );
  }
}