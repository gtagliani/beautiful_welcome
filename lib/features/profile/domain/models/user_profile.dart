import 'weight_entry.dart';

class UserProfile {
  final String name;
  final DateTime? birthDate;
  final List<WeightEntry> weightHistory;
  final String localeCode;
  final String weightUnit;

  UserProfile({
    required this.name,
    this.birthDate,
    required this.weightHistory,
    required this.localeCode,
    this.weightUnit = 'kg',
  });

  UserProfile copyWith({
    String? name,
    DateTime? birthDate,
    List<WeightEntry>? weightHistory,
    String? localeCode,
    String? weightUnit,
  }) {
    return UserProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      weightHistory: weightHistory ?? this.weightHistory,
      localeCode: localeCode ?? this.localeCode,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'weightHistory': weightHistory.map((e) => e.toJson()).toList(),
      'localeCode': localeCode,
      'weightUnit': weightUnit,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var list = json['weightHistory'] as List<dynamic>? ?? [];
    List<WeightEntry> weights = list.map((e) => WeightEntry.fromJson(e)).toList();
    
    return UserProfile(
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      weightHistory: weights,
      localeCode: json['localeCode'] as String? ?? 'system',
      weightUnit: json['weightUnit'] as String? ?? 'kg',
    );
  }
}
