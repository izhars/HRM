import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/announcement.dart';
import 'auth_service.dart';

class AnnouncementService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<List<Announcement>> fetchAnnouncements() async {
    final token = await _authService.getToken();

    try {
      // Add Authorization header with token if available
      final response = await http
          .get(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (token != null && token.isNotEmpty)
            HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List announcements = data['announcements'];
        return announcements.map((a) => Announcement.fromJson(a)).toList();
      } else {
        throw HttpException(
          'Failed to load announcements: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
