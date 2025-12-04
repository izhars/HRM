import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/Award.dart';
import 'auth_service.dart';

class AwardService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Award>> fetchMyAwards() async {
    final url = Uri.parse('$baseUrl/awards/me');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'];
        return data.map((award) => Award.fromJson(award)).toList();
      } else {
        throw Exception('Failed to load awards: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching awards: $e');
    }
  }
}
