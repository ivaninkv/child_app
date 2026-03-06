import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/models.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class EventsLoad extends EventsEvent {
  final String childId;

  const EventsLoad(this.childId);

  @override
  List<Object?> get props => [childId];
}

class EventsAdd extends EventsEvent {
  final String childId;
  final String title;
  final String description;
  final DateTime date;
  final String? category;
  final List<String> photoIds;

  const EventsAdd({
    required this.childId,
    required this.title,
    required this.description,
    required this.date,
    this.category,
    this.photoIds = const [],
  });

  @override
  List<Object?> get props => [
    childId,
    title,
    description,
    date,
    category,
    photoIds,
  ];
}

class EventsUpdate extends EventsEvent {
  final Event event;

  const EventsUpdate(this.event);

  @override
  List<Object?> get props => [event];
}

class EventsDelete extends EventsEvent {
  final String id;
  final String childId;

  const EventsDelete({required this.id, required this.childId});

  @override
  List<Object?> get props => [id, childId];
}

class EventsAddPhoto extends EventsEvent {
  final String eventId;
  final String photoId;

  const EventsAddPhoto({required this.eventId, required this.photoId});

  @override
  List<Object?> get props => [eventId, photoId];
}

class EventsRemovePhoto extends EventsEvent {
  final String eventId;
  final String photoId;

  const EventsRemovePhoto({required this.eventId, required this.photoId});

  @override
  List<Object?> get props => [eventId, photoId];
}

// State
abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<Event> events;

  const EventsLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class EventsAdded extends EventsState {
  final List<Event> events;

  const EventsAdded(this.events);

  @override
  List<Object?> get props => [events];
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();

  EventsBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(EventsInitial()) {
    on<EventsLoad>(_onLoad);
    on<EventsAdd>(_onAdd);
    on<EventsUpdate>(_onUpdate);
    on<EventsDelete>(_onDelete);
    on<EventsAddPhoto>(_onAddPhoto);
    on<EventsRemovePhoto>(_onRemovePhoto);
  }

  Future<void> _onLoad(EventsLoad event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    try {
      final events = await _db.getEventsForChild(event.childId);
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onAdd(EventsAdd event, Emitter<EventsState> emit) async {
    try {
      final newEvent = Event(
        id: _uuid.v4(),
        childId: event.childId,
        title: event.title,
        description: event.description,
        date: event.date,
        category: event.category,
        createdAt: DateTime.now(),
        photoIds: event.photoIds,
      );

      await _db.insertEvent(newEvent);
      final events = await _db.getEventsForChild(event.childId);
      emit(EventsAdded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onUpdate(EventsUpdate event, Emitter<EventsState> emit) async {
    try {
      await _db.updateEvent(event.event);
      final events = await _db.getEventsForChild(event.event.childId);
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onDelete(EventsDelete event, Emitter<EventsState> emit) async {
    try {
      await _db.deleteEvent(event.id);
      final events = await _db.getEventsForChild(event.childId);
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onAddPhoto(
    EventsAddPhoto event,
    Emitter<EventsState> emit,
  ) async {
    try {
      final existingEvent = await _db.getEvent(event.eventId);
      if (existingEvent != null) {
        final updatedPhotoIds = List<String>.from(existingEvent.photoIds)
          ..add(event.photoId);
        final updatedEvent = existingEvent.copyWith(photoIds: updatedPhotoIds);
        await _db.updateEvent(updatedEvent);
        final events = await _db.getEventsForChild(existingEvent.childId);
        emit(EventsLoaded(events));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onRemovePhoto(
    EventsRemovePhoto event,
    Emitter<EventsState> emit,
  ) async {
    try {
      final existingEvent = await _db.getEvent(event.eventId);
      if (existingEvent != null) {
        final updatedPhotoIds = List<String>.from(existingEvent.photoIds)
          ..remove(event.photoId);
        final updatedEvent = existingEvent.copyWith(photoIds: updatedPhotoIds);
        await _db.updateEvent(updatedEvent);
        final events = await _db.getEventsForChild(existingEvent.childId);
        emit(EventsLoaded(events));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }
}
