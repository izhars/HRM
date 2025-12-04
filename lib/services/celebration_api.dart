import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/celebration.dart';
import 'api_exception.dart';
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

  /// -------------------------
  /// 🔥 COMMON API HANDLER
  /// -------------------------
  dynamic _handleResponse(http.Response response) {
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? "Something went wrong",
    );
  }

  /// 📅 TODAY CELEBRATIONS
  Future<CelebrationResponse> getTodayCelebrations({
    String? date,
    String? department,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();

    final query = {
      "page": page.toString(),
      "limit": limit.toString(),
      if (date != null) "date": date,
      if (department != null) "department": department,
    };

    final uri = Uri.parse('$baseUrl/celebrations/all-today')
        .replace(queryParameters: query);

    final response = await http.get(uri, headers: headers);

    final jsonData = _handleResponse(response);

    return CelebrationResponse.fromJson(jsonData);
  }

  /// 🔮 UPCOMING CELEBRATIONS
  Future<CelebrationResponse> getUpcomingCelebrations({
    String? date,
    String? department,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();

    final query = {
      "page": page.toString(),
      "limit": limit.toString(),
      "upcomingDays": upcomingDays.toString(),
      if (date != null) "date": date,
      if (department != null) "department": department,
    };

    final uri = Uri.parse('$baseUrl/celebrations/all-upcoming')
        .replace(queryParameters: query);

    final response = await http.get(uri, headers: headers);

    return CelebrationResponse.fromJson(_handleResponse(response));
  }

  /// 🎂 BIRTHDAYS
  Future<CelebrationResponse> getBirthdays({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();

    final query = {
      "page": page.toString(),
      "limit": limit.toString(),
      if (date != null) "date": date,
      if (department != null) "department": department,
      if (includeUpcoming) ...{
        "includeUpcoming": "true",
        "upcomingDays": upcomingDays.toString()
      }
    };

    final uri = Uri.parse('$baseUrl/celebrations/birthdays')
        .replace(queryParameters: query);

    final response = await http.get(uri, headers: headers);

    return CelebrationResponse.fromJson(_handleResponse(response));
  }

  /// 💍 MARRIAGE ANNIVERSARY
  Future<CelebrationResponse> getMarriageAnniversaries({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();

    final query = {
      "page": page.toString(),
      "limit": limit.toString(),
      if (date != null) "date": date,
      if (department != null) "department": department,
      if (includeUpcoming) ...{
        "includeUpcoming": "true",
        "upcomingDays": upcomingDays.toString()
      }
    };

    final uri = Uri.parse('$baseUrl/celebrations/marriage-anniversaries')
        .replace(queryParameters: query);

    final response = await http.get(uri, headers: headers);

    return CelebrationResponse.fromJson(_handleResponse(response));
  }

  /// 🏢 WORK ANNIVERSARY
  Future<CelebrationResponse> getWorkAnniversaries({
    String? date,
    String? department,
    bool includeUpcoming = false,
    int upcomingDays = 7,
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();

    final query = {
      "page": page.toString(),
      "limit": limit.toString(),
      if (date != null) "date": date,
      if (department != null) "department": department,
      if (includeUpcoming) ...{
        "includeUpcoming": "true",
        "upcomingDays": upcomingDays.toString()
      }
    };

    final uri = Uri.parse('$baseUrl/celebrations/work-anniversaries')
        .replace(queryParameters: query);

    final response = await http.get(uri, headers: headers);

    return CelebrationResponse.fromJson(_handleResponse(response));
  }
}
