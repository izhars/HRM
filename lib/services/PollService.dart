import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import 'auth_service.dart';

class PollService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all available polls
  Future<List<dynamic>> fetchPolls() async {
    try {
      final url = Uri.parse('$baseUrl/polls');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['polls'] != null) {
          return data['polls'];
        } else {
          throw Exception('Failed to load polls: Invalid response structure');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Submit vote for a specific poll option
  Future<Map<String, dynamic>> votePoll(String pollId, int optionIndex) async {
    try {
      final url = Uri.parse('$baseUrl/polls/$pollId/vote');
      final headers = await _getHeaders();
      final body = json.encode({'opts': optionIndex});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Vote recorded'
        };
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Vote submission failed: $e');
    }
  }

  /// Fetch poll results with chart data
  Future<Map<String, dynamic>> fetchPollResults(String pollId) async {
    try {
      final url = Uri.parse('$baseUrl/polls/$pollId');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['poll'] != null) {
          return data['poll'];
        } else {
          throw Exception('Failed to load poll results: Invalid response structure');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Results fetch error: $e');
    }
  }
}
