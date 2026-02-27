import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String childId;
  final String title;
  final String description;
  final DateTime date;
  final String? category;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.childId,
    required this.title,
    required this.description,
    required this.date,
    this.category,
    required this.createdAt,
  });

  Event copyWith({
    String? id,
    String? childId,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      category: map['category'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [
    id,
    childId,
    title,
    description,
    date,
    category,
    createdAt,
  ];
}
