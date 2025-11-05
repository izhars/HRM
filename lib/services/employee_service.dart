import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import 'auth_service.dart';

class EmployeeService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getAllHRs() async {
    final token = await _authService.getToken();
    final url = Uri.parse('$baseUrl/employees/hr');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final hrs = List<Map<String, dynamic>>.from(data['hrs']);
      return hrs;
    } else {
      throw Exception('Failed to load HR list');
    }
  }
}
