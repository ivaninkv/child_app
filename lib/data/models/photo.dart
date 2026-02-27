import 'package:equatable/equatable.dart';

class Photo extends Equatable {
  final String id;
  final String childId;
  final String imagePath;
  final DateTime date;
  final List<String> tags;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.childId,
    required this.imagePath,
    required this.date,
    required this.tags,
    required this.createdAt,
  });

  Photo copyWith({
    String? id,
    String? childId,
    String? imagePath,
    DateTime? date,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'image_path': imagePath,
      'date': date.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map, {List<String>? tags}) {
    return Photo(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      imagePath: map['image_path'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      tags: tags ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [id, childId, imagePath, date, tags, createdAt];
}
