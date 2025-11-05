// device_info.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static final _deviceInfo = DeviceInfoPlugin();

  static Future<String> model() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.model;
    } else {
      final info = await _deviceInfo.iosInfo;
      return info.model;
    }
  }

  static Future<String> os() async {
    if (Platform.isAndroid) return 'Android';
    return 'iOS';
  }
}