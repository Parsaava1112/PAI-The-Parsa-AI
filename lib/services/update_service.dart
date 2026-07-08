import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

class UpdateService {
  /// بررسی نسخه سرور و مقایسه با نسخه محلی
  /// در صورت وجود آپدیت، Map اطلاعات برمی‌گرداند وگرنه null
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await ApiService.get('version');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final remoteVersion = data['version'] as String;

        final packageInfo = await PackageInfo.fromPlatform();
        final localVersion = packageInfo.version;

        if (_isVersionGreater(remoteVersion, localVersion)) {
          return data; // نسخه سرور جدیدتر است
        }
      }
    } catch (_) {
      // در صورت خطا (مثل نبود اینترنت) نادیده بگیرید
    }
    return null; // آپدیتی موجود نیست
  }

  /// مقایسه دو نسخه semantic versioning (مثال: 1.2.3 > 1.2.0)
  static bool _isVersionGreater(String remote, String local) {
    final remoteParts = remote.split('.').map(int.parse).toList();
    final localParts = local.split('.').map(int.parse).toList();

    for (int i = 0; i < remoteParts.length; i++) {
      final r = remoteParts[i];
      final l = i < localParts.length ? localParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    // اگر طول نسخه محلی بیشتر باشد و ارقام اضافی غیرصفر باشند (غیرمعمول)
    // در حالت عادی برابر یا جدیدتر نیست
    return false;
  }

  /// بررسی موجود بودن آپدیت (با توجه به نسخه محلی)
  /// این متد دیگر اجباری نیست، چون checkForUpdate خودش فیلتر می‌کند.
  static Future<bool> isUpdateAvailable(Map<String, dynamic> updateData) async {
    final remoteVersion = updateData['version'] as String;
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = packageInfo.version;
    return _isVersionGreater(remoteVersion, localVersion);
  }
}