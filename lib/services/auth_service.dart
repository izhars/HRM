import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../app/constants.dart';

class AuthService {
  static const _authTokenKey = 'auth_token';
  static const _userDataKey = 'user_data';
  static const _userIdKey = 'id';

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get unique device ID
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id ?? androidInfo.serialNumber ?? 'unknown';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      print('Device ID fetch error: $e');
    }
    return 'unknown';
  }

  /// Login user
  Future<User?> login(String email, String password) async {
    print('📱 Starting login for email: $email');

    final deviceId = await _getDeviceId();
    print('🔑 Device ID: $deviceId');

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/login');
    print('🌐 Login URL: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
      }),
    );

    print('📩 Response status: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to login. Status code: ${response.statusCode}, body: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    print('📝 Parsed JSON data: $data');

    if (data['success'] != true || data['user'] == null) {
      throw Exception(data['message'] ?? 'Login failed');
    }

    final token = data['token'];
    print('🔐 Token received: $token');

    final user = User.fromJson(data['user']);
    print('👤 User parsed: ${user.toJson()}');

    await _storeAuthData(token, user, data['user']);
    print('💾 Auth data stored successfully');

    return user;
  }


  /// Register new user
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      return response['success'];
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// Upload profile picture
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token found. Please login.');

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/profile-picture');

    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (fileExtension == 'png') mimeType = 'image/png';
    if (fileExtension == 'gif') mimeType = 'image/gif';
    if (fileExtension == 'webp') mimeType = 'image/webp';

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) throw Exception('Upload failed: $body');

    return jsonDecode(body);
  }

  /// Send forgot password request
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['message'] ?? 'Failed to send reset link');
    }
  }

  /// Fetch current user
  Future<User?> fetchMe() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token found. Please login.');

    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/me');
    final response = await http.get(url, headers: _buildHeaders(token));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user. Status code: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true || data['user'] == null) {
      throw Exception(data['message'] ?? 'Failed to fetch user');
    }

    return User.fromJson(data['user']);
  }

  /// Check verification
  Future<Map<String, dynamic>?> checkVerification() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/check-verification'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to check verification: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Logout
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/logout'),
          headers: _buildHeaders(token),
        );
      } catch (e) {
        print('Logout API failed: $e');
      }
    }
    await _clearAuthData();
  }

  /// Storage & utility methods
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserRole() async {
    final userData = await _secureStorage.read(key: _userDataKey);
    if (userData == null) return null;
    final userMap = jsonDecode(userData);
    return userMap['role'];
  }

  Future<User?> getCurrentUser() async {
    final userData = await _secureStorage.read(key: _userDataKey);
    return userData != null ? User.fromJson(jsonDecode(userData)) : null;
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }

  Map<String, String> _buildHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<void> _storeAuthData(String token, User user, Map<String, dynamic> userJson) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
    await _secureStorage.write(key: _userIdKey, value: user.id);
    await _secureStorage.write(key: _userDataKey, value: jsonEncode(userJson));
  }

  Future<void> _clearAuthData() async {
    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _userDataKey);
    await _secureStorage.delete(key: _userIdKey);
  }
}
