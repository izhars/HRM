// faq_model.dart
class FAQ {
  final String id;
  final String name;
  final String description;
  final List<FAQItem> faqs;

  FAQ({
    required this.id,
    required this.name,
    required this.description,
    required this.faqs,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    var faqItems = (json['faqs'] as List)
        .map((item) => FAQItem.fromJson(item))
        .toList();

    return FAQ(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      faqs: faqItems,
    );
  }
}

class FAQItem {
  final String id;
  final String question;
  final String answer;

  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['_id'],
      question: json['question'],
      answer: json['answer'],
    );
  }
}
