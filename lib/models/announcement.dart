class Announcement {
  final String id;
  final String title;
  final String description;
  final String type;
  final String priority;
  final bool isActive;
  final String publishDate;
  final CreatedBy createdBy;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.isActive,
    required this.publishDate,
    required this.createdBy,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      priority: json['priority'],
      isActive: json['isActive'],
      publishDate: json['publishDate'],
      createdBy: CreatedBy.fromJson(json['createdBy']),
    );
  }
}

class CreatedBy {
  final String firstName;
  final String lastName;
  final String email;

  CreatedBy({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
    );
  }
}
