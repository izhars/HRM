class FeedbackModel {
  final String message;
  final String category;
  final bool isAnonymous;

  FeedbackModel({
    required this.message,
    this.category = 'other',
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'category': category,
    'isAnonymous': isAnonymous,
  };
}
