import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../app/constants.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final ApiService _apiService = ApiService();
  final _secureStorage = const FlutterSecureStorage();

  /// Login user and save token + user locally
  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success'] == true && data['user'] != null) {
        final token = data['token'];
        final user = User.fromJson(data['user']);

        // CORRECTED: Get ID from user object, not root level
        final id = user.id; // This is the correct way

        // Save token and user locally
        await _secureStorage.write(key: 'auth_token', value: token);
        await _secureStorage.write(key: 'id', value: id);
        await _secureStorage.write(key: 'user_data', value: jsonEncode(data['user']));

        return user;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } else {
      throw Exception('Failed to login. Status code: ${response.statusCode}');
    }
  }

  /// Register user
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

  /// Fetch current user from API using token
  Future<User?> fetchMe() async {
    final token = await getToken(); // Get token from secure storage

    if (token == null) {
      throw Exception('No auth token found. Please login.');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Pass token in Authorization header
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['success'] == true && data['user'] != null) {
        return User.fromJson(data['user']);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch user');
      }
    } else {
      throw Exception('Failed to fetch user. Status code: ${response.statusCode}');
    }
  }


  /// Logout user
  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_data');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null;
  }

  Future<String?> getUserRole() async {
    final userData = await _secureStorage.read(key: 'user_data');
    if (userData == null) return null;

    final userMap = jsonDecode(userData);
    return userMap['role']; // Assuming your user JSON has a "role" field
  }

  Future<User?> getCurrentUser() async {
    final userData = await _secureStorage.read(key: 'user_data');
    if (userData == null) return null;
    return User.fromJson(jsonDecode(userData));
  }

  /// Fetch auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
}
