class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;

  WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
  });

  WeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weight,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}
