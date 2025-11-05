class Employee {
  final String id;
  final String name;
  final String email;
  final String position;
  final String departmentId;
  final String phone;
  final DateTime hireDate;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.departmentId,
    required this.phone,
    required this.hireDate,
    this.isActive = true,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      position: json['position'] ?? '',
      departmentId: json['department_id'] ?? '',
      phone: json['phone'] ?? '',
      hireDate: DateTime.parse(json['hire_date'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'position': position,
      'department_id': departmentId,
      'phone': phone,
      'hire_date': hireDate.toIso8601String(),
      'is_active': isActive,
    };
  }
}