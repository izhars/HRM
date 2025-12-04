import '../services/network_service.dart';
import 'api_exception.dart';

class AttendanceService {
  final NetworkService _network = NetworkService();

  // ---------------------------------------------------------
  // 🔥 Check-In
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String address,
    required String deviceInfo,
  }) async {
    try {
      return await _network.post(
        "/attendance/check-in",
        {
          "latitude": latitude,
          "longitude": longitude,
          "address": address,
          "deviceInfo": deviceInfo,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Check-Out
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String address,
    required String deviceInfo,
  }) async {
    try {
      return await _network.post(
        "/attendance/check-out",
        {
          "latitude": latitude,
          "longitude": longitude,
          "address": address,
          "deviceInfo": deviceInfo,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Fetch Today's Attendance
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> fetchTodayAttendance() async {
    try {
      return await _network.get("/attendance/today");
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Fetch My Attendance (month/year filter)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> fetchMyAttendance({
    int? month,
    int? year,
  }) async {
    try {
      String url = "/attendance/my-attendance";

      if (month != null && year != null) {
        url += "?month=$month&year=$year";
      }

      return await _network.get(url);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Monthly Work Hours Chart
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getMonthlyWorkHours({
    required int month,
    required int year,
  }) async {
    try {
      return await _network.get(
        "/attendance/work-hours-chart-monthly?month=$month&year=$year",
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Work Hours Calculation Helper
  // ---------------------------------------------------------
  double? getWorkHours(Map<String, dynamic> attendance) {
    if (attendance['workHours'] != null) {
      return attendance['workHours'].toDouble();
    }

    final checkInTime = attendance['checkIn']?['time'];
    final checkOutTime = attendance['checkOut']?['time'];

    if (checkInTime != null && checkOutTime != null) {
      try {
        final checkIn = DateTime.parse(checkInTime);
        final checkOut = DateTime.parse(checkOutTime);
        return checkOut.difference(checkIn).inMinutes / 60.0;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ---------------------------------------------------------
  // 🔥 Format Work Hours
  // ---------------------------------------------------------
  String formatWorkHours(double? hours) {
    if (hours == null) return "N/A";

    final intHours = hours.floor();
    final minutes = ((hours - intHours) * 60).round();

    if (minutes == 0) return "${intHours}h";
    return "${intHours}h ${minutes}m";
  }
}
