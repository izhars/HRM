class ApiEndpoints {
  // Auth endpoints
  static const String login = 'auth/login';
  static const String register = 'auth/register';
  static const String logout = 'auth/logout';
  static const String me = 'auth/me';

  // Attendance endpoints
  static const String checkIn = 'attendance/check-in';
  static const String checkOut = 'attendance/check-out';
  static const String todayAttendance = 'attendance/today';
  static const String myAttendance = 'attendance/my-attendance';
  static const String attendanceHistory = 'attendance/history';

  // User endpoints
  static const String profile = 'users/profile';
  static const String updateProfile = 'users/update-profile';

  // Leave endpoints
  static const String leaves = 'leaves';
  static const String applyLeave = 'leaves/apply';

  // Other endpoints
  static const String holidays = 'holidays';
  static const String birthdays = 'events/birthdays';
  static const String anniversaries = 'events/anniversaries';
}