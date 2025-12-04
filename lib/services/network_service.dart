import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class NetworkService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final _authService = AuthService();

  // ---------------------------------------------------------
  // 🔥 UNIVERSAL RETRY WRAPPER
  // ---------------------------------------------------------
  Future<T> retry<T>(
      Future<T> Function() fn, {
        int retries = AppConstants.maxRetries,
        Duration initialDelay = const Duration(milliseconds: 600),
      }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await fn();
      } catch (e) {
        if (attempt >= retries) rethrow;

        await Future.delayed(delay);
        delay *= 2;
        attempt++;
      }
    }
  }

  // ---------------------------------------------------------
  // 🔥 GET AUTH HEADERS
  // ---------------------------------------------------------
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  // ---------------------------------------------------------
  // 🔥 CORE REQUEST HANDLER (ApiException integrated)
  // ---------------------------------------------------------
  Future<dynamic> _handleRequest(
      Future<http.Response> Function() requestFn,
      ) async {
    try {
      final response = await requestFn().timeout(AppConstants.apiTimeout);

      final status = response.statusCode;

      // Success Response
      if (status >= 200 && status < 300) {
        return jsonDecode(response.body);
      }

      // Failure → Throw structured ApiException
      throw ApiException(
        statusCode: status,
        message: _extractErrorMessage(response),
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: "No internet connection",
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: "Request timed out",
      );
    } catch (e) {
      if (e is ApiException) rethrow;

      throw ApiException(
        statusCode: 0,
        message: "Unexpected error: $e",
      );
    }
  }

  // ---------------------------------------------------------
  // 🔥 Extract server error message safely
  // ---------------------------------------------------------
  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded['message'] ?? "Something went wrong";
    } catch (_) {
      return "Something went wrong (${response.statusCode})";
    }
  }

  // ---------------------------------------------------------
  // 🔥 PUBLIC METHODS (GET/POST/PUT/DELETE)
  // ---------------------------------------------------------
  Future<dynamic> get(String endpoint) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
      });
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        );
      });
    });
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        );
      });
    });
  }

  Future<dynamic> delete(String endpoint) async {
    return retry(() async {
      final headers = await _headers();
      return _handleRequest(() {
        return http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
        );
      });
    });
  }
}
