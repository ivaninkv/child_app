import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/models.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class RemindersEvent extends Equatable {
  const RemindersEvent();

  @override
  List<Object?> get props => [];
}

class RemindersLoad extends RemindersEvent {
  final String childId;

  const RemindersLoad(this.childId);

  @override
  List<Object?> get props => [childId];
}

class RemindersUpdateSettings extends RemindersEvent {
  final ReminderSettings settings;

  const RemindersUpdateSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class RemindersToggle extends RemindersEvent {
  final String childId;
  final bool enabled;

  const RemindersToggle({required this.childId, required this.enabled});

  @override
  List<Object?> get props => [childId, enabled];
}

// State
abstract class RemindersState extends Equatable {
  const RemindersState();

  @override
  List<Object?> get props => [];
}

class RemindersInitial extends RemindersState {}

class RemindersLoading extends RemindersState {}

class RemindersLoaded extends RemindersState {
  final ReminderSettings? settings;

  const RemindersLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class RemindersError extends RemindersState {
  final String message;

  const RemindersError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();

  RemindersBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(RemindersInitial()) {
    on<RemindersLoad>(_onLoad);
    on<RemindersUpdateSettings>(_onUpdateSettings);
    on<RemindersToggle>(_onToggle);
  }

  Future<void> _onLoad(
    RemindersLoad event,
    Emitter<RemindersState> emit,
  ) async {
    emit(RemindersLoading());
    try {
      final settings = await _db.getReminderSettingsForChild(event.childId);
      emit(RemindersLoaded(settings));
    } catch (e) {
      emit(RemindersError(e.toString()));
    }
  }

  Future<void> _onUpdateSettings(
    RemindersUpdateSettings event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final existing = await _db.getReminderSettingsForChild(
        event.settings.childId,
      );
      if (existing != null) {
        await _db.updateReminderSettings(event.settings);
      } else {
        await _db.insertReminderSettings(event.settings);
      }
      emit(RemindersLoaded(event.settings));
    } catch (e) {
      emit(RemindersError(e.toString()));
    }
  }

  Future<void> _onToggle(
    RemindersToggle event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final existing = await _db.getReminderSettingsForChild(event.childId);
      if (existing != null) {
        final updated = existing.copyWith(enabled: event.enabled);
        await _db.updateReminderSettings(updated);
        emit(RemindersLoaded(updated));
      }
    } catch (e) {
      emit(RemindersError(e.toString()));
    }
  }
}
