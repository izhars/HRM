import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/feedback.dart';
import 'auth_service.dart';

class FeedbackService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> sendFeedback(FeedbackModel feedback) async {
    try {
      // ✅ Correct endpoint
      final url = Uri.parse('$baseUrl/feedbacks');

      // ✅ Await token before using
      final token = await _authService.getToken();

      final headers = {
        'Content-Type': 'application/json',
        if (!feedback.isAnonymous && token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(feedback.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['feedback']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to send feedback'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ Optionally fetch feedbacks
  Future<List<dynamic>> getAllFeedbacks() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/feedbacks'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['feedbacks'] ?? [];
      } else {
        throw Exception('Failed to fetch feedbacks');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
