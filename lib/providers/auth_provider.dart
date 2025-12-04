import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 🔹 Login and save token
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send forgot password request
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.forgotPassword(email.trim());
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔹 Register new user
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.register(name, email, password);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔹 Extract clean error message from various error formats
  String _extractErrorMessage(dynamic error) {
    // If it's already a string, clean it up
    if (error is String) {
      return error.replaceFirst('Exception:', '').trim();
    }

    // If it's an Exception object
    if (error is Exception) {
      String msg = error.toString().replaceFirst('Exception:', '').trim();

      // Try to parse if it's a JSON string
      try {
        final decoded = jsonDecode(msg);
        if (decoded is Map && decoded.containsKey('message')) {
          return decoded['message'].toString();
        }
      } catch (_) {
        // Not JSON, return as is
      }

      return msg;
    }

    // If it's a Map (JSON object)
    if (error is Map) {
      if (error.containsKey('message')) {
        return error['message'].toString();
      }
      return error.toString();
    }

    // Fallback
    return error.toString();
  }

  /// 🔹 Logout and delete stored token
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// 🔹 Check if auth token exists
  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  /// 🔹 Clear error message
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}