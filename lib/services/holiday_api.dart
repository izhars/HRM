import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import 'auth_service.dart';

class HolidayService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> fetchHolidays({int? year, int? month}) async {
    final token = await _authService.getToken();

    // Build query parameters
    Map<String, String> queryParams = {};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();

    // Create URI with query parameters
    final uri = Uri.parse('$baseUrl/holidays').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List data = jsonResponse['data'];
      return data.map((e) => {
        "name": e['name'],
        "date": DateTime.parse(e['date']),
        "description": e['description'] ?? "",
      }).toList();
    } else {
      throw Exception("Failed to load holidays");
    }
  }


  // Fetch upcoming holidays only
  Future<List<Map<String, dynamic>>> fetchUpcomingHolidays() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/holidays/upcoming'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List data = jsonResponse['data']; // Access the 'data' field

      return data.map((e) => {
        "name": e['name'],
        "date": DateTime.parse(e['date']),
        "description": e['description'] ?? "",
        "type": e['type'] ?? "",
        "weekday": e['weekday'] ?? "",
        "id": e['id'] ?? e['_id'],
      }).toList();
    } else {
      throw Exception("Failed to load upcoming holidays: ${response.statusCode}");
    }
  }
}
