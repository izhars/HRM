class ComboOff {
  final String id;
  final String employeeId;
  final DateTime date;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComboOff({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.reason,
    required this.status,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create ComboOff from JSON
  factory ComboOff.fromJson(Map<String, dynamic> json) {
    return ComboOff(
      id: json['_id'] ?? '',
      employeeId: json['employee'] is Map
          ? json['employee']['_id'] ?? ''
          : json['employee'] ?? '',
      date: json['workDate'] != null
          ? DateTime.parse(json['workDate'])
          : DateTime.now(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'] is Map
          ? json['approvedBy']['_id']
          : json['approvedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Method to convert ComboOff to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employee': employeeId,
      'workDate': date.toIso8601String(),
      'reason': reason,
      'status': status,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // CopyWith method for creating modified copies
  ComboOff copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    String? reason,
    String? status,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComboOff(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isReviewed => approvedBy != null;

  // Format date for display
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Format created date for display
  String get formattedCreatedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}';
  }

  @override
  String toString() {
    return 'ComboOff{id: $id, employeeId: $employeeId, date: $date, reason: $reason, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ComboOff &&
        other.id == id &&
        other.employeeId == employeeId &&
        other.date == date &&
        other.reason == reason &&
        other.status == status &&
        other.approvedBy == approvedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    employeeId.hashCode ^
    date.hashCode ^
    reason.hashCode ^
    status.hashCode ^
    approvedBy.hashCode;
  }
}