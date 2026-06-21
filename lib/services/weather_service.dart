import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String apiKey = '16634dddbce86a80e27bb54b3fc12f74'; // جایگزین کن

  // بازگرداندن یک نقشه شامل condition و isDay
  static Future<Map<String, dynamic>?> getCurrentWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?'
        'lat=${position.latitude}&lon=${position.longitude}'
        '&appid=$apiKey&units=metric',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final condition = data['weather'][0]['main'] as String; // Rain, Clear, Clouds, etc.
        final icon = data['weather'][0]['icon'] as String;      // e.g., "10d" or "01n"
        final isDay = icon.endsWith('d'); // d = day, n = night
        return {
          'condition': condition,
          'isDay': isDay,
        };
      }
    } catch (_) {}
    return null;
  }
}