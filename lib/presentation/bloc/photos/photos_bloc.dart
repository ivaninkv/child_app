import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/models.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class PhotosEvent extends Equatable {
  const PhotosEvent();

  @override
  List<Object?> get props => [];
}

class PhotosLoad extends PhotosEvent {
  final String childId;

  const PhotosLoad(this.childId);

  @override
  List<Object?> get props => [childId];
}

class PhotosAdd extends PhotosEvent {
  final String childId;
  final String imagePath;
  final String? thumbnailPath;
  final DateTime date;
  final List<String> tags;

  const PhotosAdd({
    required this.childId,
    required this.imagePath,
    this.thumbnailPath,
    required this.date,
    required this.tags,
  });

  @override
  List<Object?> get props => [childId, imagePath, thumbnailPath, date, tags];
}

class PhotosUpdate extends PhotosEvent {
  final Photo photo;

  const PhotosUpdate(this.photo);

  @override
  List<Object?> get props => [photo];
}

class PhotosDelete extends PhotosEvent {
  final String id;
  final String childId;

  const PhotosDelete({required this.id, required this.childId});

  @override
  List<Object?> get props => [id, childId];
}

class PhotosLoadTags extends PhotosEvent {}

// State
abstract class PhotosState extends Equatable {
  const PhotosState();

  @override
  List<Object?> get props => [];
}

class PhotosInitial extends PhotosState {}

class PhotosLoading extends PhotosState {}

class PhotosLoaded extends PhotosState {
  final List<Photo> photos;
  final List<String> availableTags;

  const PhotosLoaded(this.photos, {this.availableTags = const []});

  @override
  List<Object?> get props => [photos, availableTags];
}

class PhotosError extends PhotosState {
  final String message;

  const PhotosError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();
  String? _currentChildId;

  PhotosBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(PhotosInitial()) {
    on<PhotosLoad>(_onLoad);
    on<PhotosAdd>(_onAdd);
    on<PhotosUpdate>(_onUpdate);
    on<PhotosDelete>(_onDelete);
    on<PhotosLoadTags>(_onLoadTags);
  }

  Future<void> _onLoad(PhotosLoad event, Emitter<PhotosState> emit) async {
    emit(PhotosLoading());
    _currentChildId = event.childId;
    try {
      final photos = await _db.getPhotosForChild(event.childId);
      final tags = await _db.getAllTags();
      emit(PhotosLoaded(photos, availableTags: tags));
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> _onAdd(PhotosAdd event, Emitter<PhotosState> emit) async {
    try {
      final photo = Photo(
        id: _uuid.v4(),
        childId: event.childId,
        imagePath: event.imagePath,
        thumbnailPath: event.thumbnailPath,
        date: event.date,
        tags: event.tags,
        createdAt: DateTime.now(),
      );

      await _db.insertPhoto(photo);
      final photos = await _db.getPhotosForChild(event.childId);
      final tags = await _db.getAllTags();
      emit(PhotosLoaded(photos, availableTags: tags));
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> _onUpdate(PhotosUpdate event, Emitter<PhotosState> emit) async {
    try {
      await _db.updatePhoto(event.photo);
      if (_currentChildId != null) {
        final photos = await _db.getPhotosForChild(_currentChildId!);
        final tags = await _db.getAllTags();
        emit(PhotosLoaded(photos, availableTags: tags));
      }
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> _onDelete(PhotosDelete event, Emitter<PhotosState> emit) async {
    try {
      await _db.deletePhoto(event.id);
      final photos = await _db.getPhotosForChild(event.childId);
      final tags = await _db.getAllTags();
      emit(PhotosLoaded(photos, availableTags: tags));
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> _onLoadTags(
    PhotosLoadTags event,
    Emitter<PhotosState> emit,
  ) async {
    final currentState = state;
    try {
      final tags = await _db.getAllTags();
      if (currentState is PhotosLoaded) {
        emit(PhotosLoaded(currentState.photos, availableTags: tags));
      }
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }
}
