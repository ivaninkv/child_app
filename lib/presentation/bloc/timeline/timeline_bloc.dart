import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class TimelineEvent extends Equatable {
  const TimelineEvent();

  @override
  List<Object?> get props => [];
}

class TimelineLoad extends TimelineEvent {
  final String childId;

  const TimelineLoad(this.childId);

  @override
  List<Object?> get props => [childId];
}

class TimelineRefresh extends TimelineEvent {
  final String childId;

  const TimelineRefresh(this.childId);

  @override
  List<Object?> get props => [childId];
}

class TimelineDeleteEvent extends TimelineEvent {
  final String id;
  final TimelineItemType type;
  final String childId;

  const TimelineDeleteEvent({
    required this.id,
    required this.type,
    required this.childId,
  });

  @override
  List<Object?> get props => [id, type, childId];
}

// State
abstract class TimelineState extends Equatable {
  const TimelineState();

  @override
  List<Object?> get props => [];
}

class TimelineInitial extends TimelineState {}

class TimelineLoading extends TimelineState {}

class TimelineLoaded extends TimelineState {
  final List<TimelineItem> items;

  const TimelineLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class TimelineError extends TimelineState {
  final String message;

  const TimelineError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class TimelineBloc extends Bloc<TimelineEvent, TimelineState> {
  final DatabaseHelper _db;

  TimelineBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(TimelineInitial()) {
    on<TimelineLoad>(_onLoad);
    on<TimelineRefresh>(_onRefresh);
    on<TimelineDeleteEvent>(_onDelete);
  }

  Future<void> _onLoad(TimelineLoad event, Emitter<TimelineState> emit) async {
    emit(TimelineLoading());
    try {
      final items = await _db.getTimelineForChild(event.childId);
      emit(TimelineLoaded(items));
    } catch (e) {
      emit(TimelineError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    TimelineRefresh event,
    Emitter<TimelineState> emit,
  ) async {
    try {
      final items = await _db.getTimelineForChild(event.childId);
      emit(TimelineLoaded(items));
    } catch (e) {
      emit(TimelineError(e.toString()));
    }
  }

  Future<void> _onDelete(
    TimelineDeleteEvent event,
    Emitter<TimelineState> emit,
  ) async {
    try {
      switch (event.type) {
        case TimelineItemType.event:
          await _db.deleteEvent(event.id);
          break;
        case TimelineItemType.photo:
          await _db.deletePhoto(event.id);
          break;
        case TimelineItemType.parameter:
          await _db.deleteParameter(event.id);
          break;
      }
      final items = await _db.getTimelineForChild(event.childId);
      emit(TimelineLoaded(items));
    } catch (e) {
      emit(TimelineError(e.toString()));
    }
  }
}
