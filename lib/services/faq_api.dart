// faq_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app/constants.dart';
import 'auth_service.dart';

class FAQService {
  final String baseUrl = "${AppConstants.apiBaseUrl}/faqs";
  final AuthService _authService = AuthService();

  // Get all FAQs
  Future<List<dynamic>> getAllFAQs() async {
    final token = await _authService.getToken();
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching FAQs: $e');
    }
  }

  // Get FAQ by ID
  Future<Map<String, dynamic>> getFAQById(String faqId) async {
    final token = await _authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$faqId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load FAQ: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching FAQ $faqId: $e');
    }
  }
}
