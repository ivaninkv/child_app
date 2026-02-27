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

  const EventsAdd({
    required this.childId,
    required this.title,
    required this.description,
    required this.date,
    this.category,
  });

  @override
  List<Object?> get props => [childId, title, description, date, category];
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
      );

      await _db.insertEvent(newEvent);
      final events = await _db.getEventsForChild(event.childId);
      emit(EventsLoaded(events));
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
}
