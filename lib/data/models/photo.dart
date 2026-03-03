import 'package:equatable/equatable.dart';

class Photo extends Equatable {
  final String id;
  final String childId;
  final String imagePath;
  final String? thumbnailPath;
  final DateTime date;
  final List<String> tags;
  final DateTime createdAt;

  // Новые поля для отображения в галерее
  final String? relatedTitle;
  final bool isFromEvent;

  // ID для навигации
  final String? eventId;
  final String? parameterId;

  const Photo({
    required this.id,
    required this.childId,
    required this.imagePath,
    this.thumbnailPath,
    required this.date,
    required this.tags,
    required this.createdAt,
    this.relatedTitle,
    this.isFromEvent = false,
    this.eventId,
    this.parameterId,
  });

  Photo copyWith({
    String? id,
    String? childId,
    String? imagePath,
    String? thumbnailPath,
    DateTime? date,
    List<String>? tags,
    DateTime? createdAt,
    String? relatedTitle,
    bool? isFromEvent,
    String? eventId,
    String? parameterId,
  }) {
    return Photo(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      relatedTitle: relatedTitle ?? this.relatedTitle,
      isFromEvent: isFromEvent ?? this.isFromEvent,
      eventId: eventId ?? this.eventId,
      parameterId: parameterId ?? this.parameterId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'image_path': imagePath,
      'thumbnail_path': thumbnailPath,
      'date': date.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map, {List<String>? tags}) {
    return Photo(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      imagePath: map['image_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      tags: tags ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [
    id,
    childId,
    imagePath,
    thumbnailPath,
    date,
    tags,
    createdAt,
    relatedTitle,
    isFromEvent,
    eventId,
    parameterId,
  ];
}
