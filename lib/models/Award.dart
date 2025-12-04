class Award {
  final String id;
  final String name;
  final String description;
  final String badgeUrl;
  final String dateAwarded;
  final String awardedBy;
  final String awardedTo;

  Award({
    required this.id,
    required this.name,
    required this.description,
    required this.badgeUrl,
    required this.dateAwarded,
    required this.awardedBy,
    required this.awardedTo,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      badgeUrl: json['badgeUrl'] ?? '',
      dateAwarded: json['dateAwarded'],
      awardedBy: json['awardedBy']?['fullName'] ?? 'Unknown',
      awardedTo: json['awardedTo']?['fullName'] ?? '',
    );
  }
}
