import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AvatarService {
  static const _avatarKey = 'avatar_path';
  static const _avatarUrl = 'https://avatar.iran.liara.run/public';

  // Get avatar either from local or fetch from API
  static Future<File?> getAvatar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localPath = prefs.getString(_avatarKey);

    if (localPath != null && File(localPath).existsSync()) {
      // Already saved locally
      return File(localPath);
    } else {
      // Download avatar
      final response = await http.get(Uri.parse(_avatarUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/avatar.png');
        await file.writeAsBytes(response.bodyBytes);
        await prefs.setString(_avatarKey, file.path);
        return file;
      }
    }
    return null;
  }

  // Optional: Clear saved avatar
  static Future<void> clearAvatar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localPath = prefs.getString(_avatarKey);
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) file.deleteSync();
      prefs.remove(_avatarKey);
    }
  }
}
