import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static Future<Map<String, String>> getAppDetails() async {
    final info = await PackageInfo.fromPlatform();

    return {
      'appName': info.appName,
      'packageName': info.packageName,
      'version': info.version,
      'buildNumber': info.buildNumber,
      'copyright': '© ${DateTime.now().year} Staff Sync Pvt.ltd. All rights reserved.',
      'madeIn': 'Made with ❤️ in India 🇮🇳',
    };
  }
}
