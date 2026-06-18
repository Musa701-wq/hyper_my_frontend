import 'dart:convert';

class Hip4Market {
  final int id;
  final String name;
  final String description;
  final String marketClass; // priceBinary, priceBucket, question, custom
  final String category;    // crypto, sports, custom
  final String? underlying;
  final double? targetPrice;
  final String? period;
  final DateTime? expiry;
  final List<Hip4Outcome> outcomes;

  Hip4Market({
    required this.id,
    required this.name,
    required this.description,
    required this.marketClass,
    required this.category,
    this.underlying,
    this.targetPrice,
    this.period,
    this.expiry,
    required this.outcomes,
  });

  factory Hip4Market.fromJson(Map<String, dynamic> json) {
    var outcomesList = json['coins'] as List? ?? json['outcomes'] as List? ?? [];
    return Hip4Market(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      marketClass: json['marketClass'] ?? json['class'] ?? 'custom',
      category: json['category'] ?? 'custom',
      underlying: json['underlying'],
      targetPrice: json['target'] != null ? double.tryParse(json['target'].toString()) : null,
      period: json['period'],
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry'].toString()) : null,
      outcomes: outcomesList.map((o) => Hip4Outcome.fromJson(o)).toList(),
    );
  }

  // Helper to get total probability sum for internal checks
  double get totalProbability => outcomes.fold(0.0, (sum, o) => sum + o.probability);
}

class Hip4Outcome {
  final int id;
  final String coinName; // e.g. #2510
  final String label;    // Yes, No, or Team
  final double price;    // Mid price 0-1
  final double probability; // 0-100%

  Hip4Outcome({
    required this.id,
    required this.coinName,
    required this.label,
    required this.price,
    required this.probability,
  });

  factory Hip4Outcome.fromJson(Map<String, dynamic> json) {
    return Hip4Outcome(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      coinName: json['coinName'] ?? '',
      label: json['label'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      probability: json['probability'] != null ? double.tryParse(json['probability'].toString()) ?? 0.0 : 0.0,
    );
  }
}
