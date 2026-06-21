import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

class UpdateService {
  /// گرفتن اطلاعات نسخه از سرور
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await ApiService.get('version');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      // اگر اینترنت نبود یا سرور در دسترس نبود، نادیده می‌گیریم
    }
    return null;
  }

  /// مقایسه نسخه فعلی برنامه با نسخه سرور
  static Future<bool> isUpdateAvailable(Map<String, dynamic> serverVersion) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version; // مثلاً "1.0.0"
    final latestVersion = serverVersion['version'] as String;
    return currentVersion != latestVersion;
  }
}