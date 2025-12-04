// --------------------- AQI Service + Models ---------------------
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/air_quality_data.dart';

class AQIService {
  // <-- put your WAQI token here
  static const String _token = '5412e87e1efe784aa7861e81376cb5ba55b145f6';
  static const String _base = 'https://api.waqi.info';

  /// Fetch AQI by geographic coordinates
  Future<AirQualityData?> fetchByGeo(double lat, double lng) async {
    final url = Uri.parse('$_base/feed/geo:$lat;$lng/?token=$_token');
    return _fetchData(url);
  }

  /// Fetch AQI by city name
  Future<AirQualityData?> fetchByCity(String city) async {
    final url = Uri.parse('$_base/feed/$city/?token=$_token');
    return _fetchData(url);
  }

  /// Internal fetch logic with error handling
  Future<AirQualityData?> _fetchData(Uri url) async {
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final Map<String, dynamic> jsonBody = jsonDecode(res.body);

      if (jsonBody['status'] != 'ok') {
        throw Exception('API status: ${jsonBody['status']}');
      }

      if (jsonBody['data'] == null) {
        throw Exception('No AQI data returned');
      }

      return AirQualityData.fromJson(jsonBody['data']);
    } catch (e) {
      debugPrint('AQI fetch error: $e');
      // Return null so UI can handle gracefully
      return null;
    }
  }
}
