import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/models.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class ChildrenEvent extends Equatable {
  const ChildrenEvent();

  @override
  List<Object?> get props => [];
}

class ChildrenLoad extends ChildrenEvent {}

class ChildrenAdd extends ChildrenEvent {
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String? avatarPath;

  const ChildrenAdd({
    required this.name,
    required this.birthDate,
    required this.gender,
    this.avatarPath,
  });

  @override
  List<Object?> get props => [name, birthDate, gender, avatarPath];
}

class ChildrenUpdate extends ChildrenEvent {
  final Child child;

  const ChildrenUpdate(this.child);

  @override
  List<Object?> get props => [child];
}

class ChildrenDelete extends ChildrenEvent {
  final String id;

  const ChildrenDelete(this.id);

  @override
  List<Object?> get props => [id];
}

// State
abstract class ChildrenState extends Equatable {
  const ChildrenState();

  @override
  List<Object?> get props => [];
}

class ChildrenInitial extends ChildrenState {}

class ChildrenLoading extends ChildrenState {}

class ChildrenLoaded extends ChildrenState {
  final List<Child> children;

  const ChildrenLoaded(this.children);

  @override
  List<Object?> get props => [children];
}

class ChildrenError extends ChildrenState {
  final String message;

  const ChildrenError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChildrenBloc extends Bloc<ChildrenEvent, ChildrenState> {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();

  ChildrenBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(ChildrenInitial()) {
    on<ChildrenLoad>(_onLoad);
    on<ChildrenAdd>(_onAdd);
    on<ChildrenUpdate>(_onUpdate);
    on<ChildrenDelete>(_onDelete);
  }

  Future<void> _onLoad(ChildrenLoad event, Emitter<ChildrenState> emit) async {
    emit(ChildrenLoading());
    try {
      final children = await _db.getAllChildren();
      emit(ChildrenLoaded(children));
    } catch (e) {
      emit(ChildrenError(e.toString()));
    }
  }

  Future<void> _onAdd(ChildrenAdd event, Emitter<ChildrenState> emit) async {
    try {
      final child = Child(
        id: _uuid.v4(),
        name: event.name,
        birthDate: event.birthDate,
        gender: event.gender,
        avatarPath: event.avatarPath,
        createdAt: DateTime.now(),
      );

      await _db.insertChild(child);
      final children = await _db.getAllChildren();
      emit(ChildrenLoaded(children));
    } catch (e) {
      emit(ChildrenError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    ChildrenUpdate event,
    Emitter<ChildrenState> emit,
  ) async {
    try {
      await _db.updateChild(event.child);
      final children = await _db.getAllChildren();
      emit(ChildrenLoaded(children));
    } catch (e) {
      emit(ChildrenError(e.toString()));
    }
  }

  Future<void> _onDelete(
    ChildrenDelete event,
    Emitter<ChildrenState> emit,
  ) async {
    try {
      await _db.deleteChild(event.id);
      final children = await _db.getAllChildren();
      emit(ChildrenLoaded(children));
    } catch (e) {
      emit(ChildrenError(e.toString()));
    }
  }
}
