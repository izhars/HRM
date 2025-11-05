import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../services/auth_service.dart';

class AttendanceService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  /// **Check-in API**
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String address,
    required String deviceInfo,
  }) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "deviceInfo": deviceInfo,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Check-in failed');
    }
  }

  /// **Check-out API** - NEW
  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String address,
    required String deviceInfo,
  }) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "deviceInfo": deviceInfo,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Check-out failed');
    }
  }

  /// **Fetch Today's Attendance**
  Future<Map<String, dynamic>> fetchTodayAttendance() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/attendance/today'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Failed to fetch attendance');
    }
  }

  /// **Get Work Hours** (Helper method)
  double? getWorkHours(Map<String, dynamic> attendance) {
    if (attendance['workHours'] != null) {
      return attendance['workHours'].toDouble();
    }

    // Calculate from checkIn/checkOut times if available
    final checkInTime = attendance['checkIn']?['time'];
    final checkOutTime = attendance['checkOut']?['time'];

    if (checkInTime != null && checkOutTime != null) {
      try {
        final checkIn = DateTime.parse(checkInTime);
        final checkOut = DateTime.parse(checkOutTime);
        return checkOut.difference(checkIn).inMinutes / 60.0;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchMyAttendance({int? month, int? year}) async {
    try {
      final token = await _authService
          .getToken(); // replace with your auth token method
      String url = '$baseUrl/attendance/my-attendance';

      // Add query params if month & year are provided
      if (month != null && year != null) {
        url += '?month=$month&year=$year';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching attendance: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// **Format Work Hours**
  String formatWorkHours(double? hours) {
    if (hours == null) return "N/A";

    final intHours = hours.floor();
    final minutes = ((hours - intHours) * 60).round();

    if (minutes == 0) return "${intHours}h";
    return "${intHours}h ${minutes}m";
  }
}