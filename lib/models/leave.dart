// models/leave.dart
import 'package:intl/intl.dart';

class Leave {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays; // Changed to double for half-day support
  final String status;
  final String reason;
  final DateTime appliedOn;
  final String? rejectionReason;
  final String? approvedByName;
  final String leaveDuration; // "full" or "half"
  final String? halfDayType; // "first_half" or "second_half"

  Leave({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.reason,
    required this.appliedOn,
    this.rejectionReason,
    this.approvedByName,
    this.leaveDuration = 'full',
    this.halfDayType,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];

    String employeeId = '';
    String employeeName = '';

    if (employee is Map<String, dynamic>) {
      employeeId = employee['employeeId'] ?? '';
      employeeName =
          '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}'.trim();
    } else if (employee is String) {
      employeeId = employee;
    }

    return Leave(
      id: json['_id'] ?? json['id'],
      employeeId: employeeId,
      employeeName: employeeName,
      leaveType: json['leaveType'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      appliedOn: DateTime.parse(json['createdAt']),
      rejectionReason: json['rejectionReason'],
      approvedByName: json['approvedBy'] != null
          ? '${json['approvedBy']['firstName'] ?? ''} ${json['approvedBy']['lastName'] ?? ''}'.trim()
          : null,
      leaveDuration: json['leaveDuration'] ?? 'full',
      halfDayType: json['halfDayType'],
    );
  }

  String get displayLeaveType =>
      leaveType[0].toUpperCase() + leaveType.substring(1);

  String get formattedDateRange {
    final start = DateFormat('MMM dd').format(startDate.toLocal());
    final end = DateFormat('MMM dd, yyyy').format(endDate.toLocal());

    if (leaveDuration == 'half') {
      final halfType = halfDayType == 'first_half' ? 'First Half' : 'Second Half';
      return '$start ($halfType)';
    }

    return '$start - $end';
  }

  String get durationDisplay {
    if (leaveDuration == 'half') {
      return '0.5 day (${halfDayType == 'first_half' ? 'First Half' : 'Second Half'})';
    }
    return '$totalDays ${totalDays == 1 ? 'day' : 'days'}';
  }
}

class LeaveBalance {
  final int casual;
  final int sick;
  final int earned;

  LeaveBalance({required this.casual, required this.sick, required this.earned});

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casual: json['casual'] ?? 0,
      sick: json['sick'] ?? 0,
      earned: json['earned'] ?? 0,
    );
  }
}