import 'package:equatable/equatable.dart';

enum Gender { male, female }

class Child extends Equatable {
  final String id;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String? avatarPath;
  final DateTime createdAt;

  const Child({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.avatarPath,
    required this.createdAt,
  });

  Child copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? avatarPath,
    DateTime? createdAt,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate.millisecondsSinceEpoch,
      'gender': gender.name,
      'avatar_path': avatarPath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String,
      name: map['name'] as String,
      birthDate: DateTime.fromMillisecondsSinceEpoch(map['birth_date'] as int),
      gender: Gender.values.firstWhere((e) => e.name == map['gender']),
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  int get ageInDays => DateTime.now().difference(birthDate).inDays;

  String get ageString {
    final days = ageInDays;
    if (days < 30) return '$days дней';
    final months = days ~/ 30;
    if (months < 12) return '$months месяцев';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years лет';
    return '$years лет $remainingMonths месяцев';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    birthDate,
    gender,
    avatarPath,
    createdAt,
  ];
}
