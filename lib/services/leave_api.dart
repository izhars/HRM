// lib/api/leaves_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import 'auth_service.dart';

class LeavesService {
  final String baseUrl = "${AppConstants.apiBaseUrl}/leaves";
  final AuthService _authService = AuthService();

  /// ✅ Fetch headers with token dynamically
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken(); // assuming getToken() is async
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Cancel leave
  Future<Map<String, dynamic>> cancelLeave(String id) async {
    final uri = Uri.parse("$baseUrl/$id/cancel");
    final headers = await _getHeaders();
    final response = await http.put(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<List<dynamic>> getPendingLeaves() async {
    final uri = Uri.parse("$baseUrl/pending/all");
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['leaves'] ?? [];
    } else {
      throw Exception(_parseError(response));
    }
  }

  /// Get leave balance
  Future<Map<String, dynamic>> getLeaveBalance() async {
    final uri = Uri.parse("$baseUrl/balance");
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['leaveBalance'] ?? {};
    } else {
      throw Exception(_parseError(response));
    }
  }

  /// ✅ Fetch all leaves (optionally filtered by status)
  Future<List<dynamic>> getMyLeaves({String? status}) async {
    final uri = Uri.parse(
      "$baseUrl${status != null ? '?status=$status' : ''}",
    );
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['leaves'] ?? [];
    } else {
      throw Exception('Failed to fetch leaves: ${response.body}');
    }
  }

  /// ✅ Apply for a new leave
  Future<Map<String, dynamic>> applyLeave(Map<String, dynamic> leaveData) async {
    final uri = Uri.parse(baseUrl);
    final headers = await _getHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(leaveData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to apply leave');
    }
  }

  /// Get all leaves (Manager/HR)
  Future<List<dynamic>> getAllLeaves({String? status, String? year}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (year != null) queryParams['year'] = year;

    final uri = Uri.parse("$baseUrl/all").replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['leaves'] ?? [];
    } else {
      throw Exception(_parseError(response));
    }
  }

  /// Approve leave
  Future<void> approveLeave(String id) async {
    final uri = Uri.parse("$baseUrl/$id/approve");
    final headers = await _getHeaders();
    final response = await http.put(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  /// Reject leave
  Future<void> rejectLeave(String id, String reason) async {
    final uri = Uri.parse("$baseUrl/$id/reject");
    final headers = await _getHeaders();
    final response = await http.put(
      uri,
      headers: headers,
      body: json.encode({"rejectionReason": reason}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  String _parseError(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['message'] ?? 'An error occurred';
    } catch (e) {
      return 'Failed to process request';
    }
  }
}
