class Department {
  final String id;
  final String name;
  final String description;
  final int employeeCount;
  final DateTime createdAt;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.employeeCount,
    required this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      employeeCount: json['employee_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'employee_count': employeeCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}