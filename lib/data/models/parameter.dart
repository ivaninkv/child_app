import 'package:equatable/equatable.dart';

class Parameter extends Equatable {
  final String id;
  final String childId;
  final DateTime date;
  final double? height;
  final double? weight;
  final double? shoeSize;
  final DateTime createdAt;

  const Parameter({
    required this.id,
    required this.childId,
    required this.date,
    this.height,
    this.weight,
    this.shoeSize,
    required this.createdAt,
  });

  Parameter copyWith({
    String? id,
    String? childId,
    DateTime? date,
    double? height,
    double? weight,
    double? shoeSize,
    DateTime? createdAt,
  }) {
    return Parameter(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      date: date ?? this.date,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      shoeSize: shoeSize ?? this.shoeSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'date': date.millisecondsSinceEpoch,
      'height': height,
      'weight': weight,
      'shoe_size': shoeSize,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Parameter.fromMap(Map<String, dynamic> map) {
    return Parameter(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      shoeSize: map['shoe_size'] as double?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [
    id,
    childId,
    date,
    height,
    weight,
    shoeSize,
    createdAt,
  ];
}
