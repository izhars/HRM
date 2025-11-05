import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/celebration.dart';
import 'auth_service.dart';

class CelebrationService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<CelebrationResponse> getTodayCelebrations({
    String? date,
    String? department,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (department != null) queryParams['department'] = department;
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrl/celebrations/all-today')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CelebrationResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Celebration endpoint not found');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load today celebrations');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching today celebrations: $e');
    }
  }

  Future<CelebrationResponse> getUpcomingCelebrations({
    String? date,
    String? department,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{
        'upcomingDays': upcomingDays.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (date != null) queryParams['date'] = date;
      if (department != null) queryParams['department'] = department;

      final uri = Uri.parse('$baseUrl/celebrations/all-upcoming')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CelebrationResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Celebration endpoint not found');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load upcoming celebrations');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching upcoming celebrations: $e');
    }
  }

  // Optional: Get specific celebration types
  Future<CelebrationResponse> getBirthdays({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (date != null) queryParams['date'] = date;
      if (department != null) queryParams['department'] = department;
      if (includeUpcoming) {
        queryParams['includeUpcoming'] = 'true';
        queryParams['upcomingDays'] = upcomingDays.toString();
      }

      final uri = Uri.parse('$baseUrl/celebrations/birthdays')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CelebrationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load birthdays');
      }
    } catch (e) {
      throw Exception('Error fetching birthdays: $e');
    }
  }

  Future<CelebrationResponse> getMarriageAnniversaries({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (date != null) queryParams['date'] = date;
      if (department != null) queryParams['department'] = department;
      if (includeUpcoming) {
        queryParams['includeUpcoming'] = 'true';
        queryParams['upcomingDays'] = upcomingDays.toString();
      }

      final uri = Uri.parse('$baseUrl/celebrations/marriage-anniversaries')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CelebrationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load marriage anniversaries');
      }
    } catch (e) {
      throw Exception('Error fetching marriage anniversaries: $e');
    }
  }

  Future<CelebrationResponse> getWorkAnniversaries({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (date != null) queryParams['date'] = date;
      if (department != null) queryParams['department'] = department;
      if (includeUpcoming) {
        queryParams['includeUpcoming'] = 'true';
        queryParams['upcomingDays'] = upcomingDays.toString();
      }

      final uri = Uri.parse('$baseUrl/celebrations/work-anniversaries')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CelebrationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load work anniversaries');
      }
    } catch (e) {
      throw Exception('Error fetching work anniversaries: $e');
    }
  }
}