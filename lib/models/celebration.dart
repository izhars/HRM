class CelebrationResponse {
  final bool success;
  final CelebrationData data;

  CelebrationResponse({required this.success, required this.data});

  factory CelebrationResponse.fromJson(Map<String, dynamic> json) {
    return CelebrationResponse(
      success: json['success'] ?? false,
      data: CelebrationData.fromJson(json['data'] ?? {}),
    );
  }
}

class CelebrationData {
  final TodayCelebrations? today;
  final UpcomingCelebrations? upcoming;

  CelebrationData({this.today, this.upcoming});

  factory CelebrationData.fromJson(Map<String, dynamic> json) {
    return CelebrationData(
      today: json['today'] != null
          ? TodayCelebrations.fromJson(json['today'])
          : null,
      upcoming: json['upcoming'] != null
          ? UpcomingCelebrations.fromJson(json['upcoming'])
          : null,
    );
  }
}

class TodayCelebrations {
  final CelebrationType birthdays;
  final CelebrationType marriageAnniversaries;
  final CelebrationType workAnniversaries;

  TodayCelebrations({
    required this.birthdays,
    required this.marriageAnniversaries,
    required this.workAnniversaries,
  });

  factory TodayCelebrations.fromJson(Map<String, dynamic> json) {
    return TodayCelebrations(
      birthdays: CelebrationType.fromJson(json['birthdays'] ?? {}),
      marriageAnniversaries: CelebrationType.fromJson(json['marriageAnniversaries'] ?? {}),
      workAnniversaries: CelebrationType.fromJson(json['workAnniversaries'] ?? {}),
    );
  }
}

class CelebrationType {
  final int count;
  final int total;
  final int page;
  final int pages;
  final List<Employee> data;

  CelebrationType({
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory CelebrationType.fromJson(Map<String, dynamic> json) {
    return CelebrationType(
      count: json['count'] ?? 0,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
      data: (json['data'] as List?)
          ?.map((e) => Employee.fromJson(e))
          .toList() ?? [],
    );
  }
}

class UpcomingCelebrations {
  final List<UpcomingEvent> birthdays;
  final List<UpcomingEvent> marriageAnniversaries;
  final List<UpcomingEvent> workAnniversaries;

  UpcomingCelebrations({
    required this.birthdays,
    required this.marriageAnniversaries,
    required this.workAnniversaries,
  });

  factory UpcomingCelebrations.fromJson(Map<String, dynamic> json) {
    return UpcomingCelebrations(
      birthdays: (json['birthdays'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ?? [],
      marriageAnniversaries: (json['marriageAnniversaries'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ?? [],
      workAnniversaries: (json['workAnniversaries'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Employee {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String department;
  final String designation; // new field
  final String? dateOfBirth;
  final String? marriageAnniversary;
  final String? dateOfJoining;
  final int? yearsOfService;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.department,
    required this.designation,
    this.dateOfBirth,
    this.marriageAnniversary,
    this.dateOfJoining,
    this.yearsOfService,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Handle department - can be either a String or an Object with 'name' field
    String departmentName = '';
    if (json['department'] != null) {
      if (json['department'] is String) {
        departmentName = json['department'];
      } else if (json['department'] is Map) {
        departmentName = json['department']['name'] ?? '';
      }
    }

    return Employee(
      id: json['_id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      department: departmentName,
      designation: json['designation'] ?? '', // new field
      dateOfBirth: json['dateOfBirth'],
      marriageAnniversary: json['marriageAnniversary'],
      dateOfJoining: json['dateOfJoining'],
      yearsOfService: json['yearsOfService'],
    );
  }
}

class UpcomingEvent {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String department;
  final String designation; // new field
  final String celebrationDate;
  final int daysUntil;
  final int? yearsOfService;

  UpcomingEvent({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.department,
    required this.designation,
    required this.celebrationDate,
    required this.daysUntil,
    this.yearsOfService,
  });

  String get fullName => '$firstName $lastName';

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    // Handle department - can be either a String or an Object with 'name' field
    String departmentName = '';
    if (json['department'] != null) {
      if (json['department'] is String) {
        departmentName = json['department'];
      } else if (json['department'] is Map) {
        departmentName = json['department']['name'] ?? '';
      }
    }

    return UpcomingEvent(
      id: json['_id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      department: departmentName,
      designation: json['designation'] ?? '', // new field
      celebrationDate: json['celebrationDate'] ?? '',
      daysUntil: json['daysUntil'] ?? 0,
      yearsOfService: json['yearsOfService'],
    );
  }
}
