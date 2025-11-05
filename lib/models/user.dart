// models/user.dart
class User {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final Department? department;
  final String? designation;
  final DateTime? dateOfJoining;
  final String? employmentType;
  final String status;
  final String? reportingManager;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final String? pfNumber;
  final String? uanNumber;
  final String? panNumber;
  final List<dynamic> documents;
  final String profilePicture;
  final bool isActive;
  final bool isVerified;
  final CreatedBy? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final int? daysToAnniversary;
  final SpouseDetails? spouseDetails;
  final Address? address;
  final Salary? salary;
  final BankDetails? bankDetails;
  final LeaveBalance? leaveBalance;
  final EmergencyContact? emergencyContact;

  User({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.department,
    this.designation,
    this.dateOfJoining,
    this.employmentType,
    required this.status,
    this.reportingManager,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.pfNumber,
    this.uanNumber,
    this.panNumber,
    required this.documents,
    required this.profilePicture,
    required this.isActive,
    required this.isVerified,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.daysToAnniversary,
    this.spouseDetails,
    this.address,
    this.salary,
    this.bankDetails,
    this.leaveBalance,
    this.emergencyContact,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      department: json['department'] != null
          ? (json['department'] is Map<String, dynamic>
          ? Department.fromJson(json['department'])
          : Department(
        id: '',
        name: json['department'].toString(),
        code: '',
        description: '',
      ))
          : null,
      designation: json['designation'],
      dateOfJoining: _tryParseDate(json['dateOfJoining']),
      employmentType: json['employmentType'],
      status: json['status'] ?? '',
      reportingManager: json['reportingManager'],
      gender: json['gender'],
      dateOfBirth: _tryParseDate(json['dateOfBirth']),
      maritalStatus: json['maritalStatus'],
      pfNumber: json['pfNumber'],
      uanNumber: json['uanNumber'],
      panNumber: json['panNumber'],
      documents: json['documents'] ?? [],
      profilePicture: json['profilePicture'] ?? '',
      isActive: json['isActive'] ?? false,
      isVerified: json['isVerified'] ?? false,
      createdBy: json['createdBy'] != null
          ? CreatedBy.fromJson(json['createdBy'])
          : null,
      createdAt: _tryParseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _tryParseDate(json['updatedAt']) ?? DateTime.now(),
      lastLogin: _tryParseDate(json['lastLogin']),
      daysToAnniversary: json['daysToAnniversary'],
      spouseDetails: json['spouseDetails'] != null
          ? SpouseDetails.fromJson(json['spouseDetails'])
          : null,
      address: json['address'] != null
          ? Address.fromJson(json['address'])
          : null,
      salary: json['salary'] != null
          ? Salary.fromJson(json['salary'])
          : null,
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
      leaveBalance: json['leaveBalance'] != null
          ? LeaveBalance.fromJson(json['leaveBalance'])
          : null,
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(json['emergencyContact'])
          : null,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department?.toJson(),
      'designation': designation,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
      'employmentType': employmentType,
      'status': status,
      'reportingManager': reportingManager,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'maritalStatus': maritalStatus,
      'pfNumber': pfNumber,
      'uanNumber': uanNumber,
      'panNumber': panNumber,
      'documents': documents,
      'profilePicture': profilePicture,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'daysToAnniversary': daysToAnniversary,
      'spouseDetails': spouseDetails?.toJson(),
      'address': address?.toJson(),
      'salary': salary?.toJson(),
      'bankDetails': bankDetails?.toJson(),
      'leaveBalance': leaveBalance?.toJson(),
      'emergencyContact': emergencyContact?.toJson(),
    };
  }

  // Helper for safe date parsing
  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class Department {
  final String id;
  final String name;
  final String code;
  final String description;

  Department({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }
}

class CreatedBy {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final int? daysToAnniversary;

  CreatedBy({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.daysToAnniversary,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      daysToAnniversary: json['daysToAnniversary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'daysToAnniversary': daysToAnniversary,
    };
  }
}

class SpouseDetails {
  final bool isWorking;

  SpouseDetails({required this.isWorking});

  factory SpouseDetails.fromJson(Map<String, dynamic> json) {
    return SpouseDetails(
      isWorking: json['isWorking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isWorking': isWorking,
    };
  }
}

class Address {
  final String city;
  final String state;
  final String country;

  Address({
    required this.city,
    required this.state,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'country': country,
    };
  }
}

class Salary {
  final double basic;
  final double hra;
  final double transport;
  final double allowances;
  final double deductions;
  final double netSalary;
  final String currency;
  final String payFrequency;

  Salary({
    required this.basic,
    required this.hra,
    required this.transport,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.currency,
    required this.payFrequency,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      basic: (json['basic'] ?? 0).toDouble(),
      hra: (json['hra'] ?? 0).toDouble(),
      transport: (json['transport'] ?? 0).toDouble(),
      allowances: (json['allowances'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      payFrequency: json['payFrequency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basic': basic,
      'hra': hra,
      'transport': transport,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': netSalary,
      'currency': currency,
      'payFrequency': payFrequency,
    };
  }
}

class BankDetails {
  final String accountNumber;
  final String bankName;
  final String ifscCode;

  BankDetails({
    required this.accountNumber,
    required this.bankName,
    required this.ifscCode,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountNumber: json['accountNumber'] ?? '',
      bankName: json['bankName'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'bankName': bankName,
      'ifscCode': ifscCode,
    };
  }
}

class LeaveBalance {
  final int casual;
  final int sick;
  final int earned;
  final int unpaid;

  LeaveBalance({
    required this.casual,
    required this.sick,
    required this.earned,
    required this.unpaid,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casual: json['casual'] ?? 0,
      sick: json['sick'] ?? 0,
      earned: json['earned'] ?? 0,
      unpaid: json['unpaid'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'casual': casual,
      'sick': sick,
      'earned': earned,
      'unpaid': unpaid,
    };
  }
}

class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}