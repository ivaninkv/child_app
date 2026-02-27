import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/models.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class ParametersEvent extends Equatable {
  const ParametersEvent();

  @override
  List<Object?> get props => [];
}

class ParametersLoad extends ParametersEvent {
  final String childId;

  const ParametersLoad(this.childId);

  @override
  List<Object?> get props => [childId];
}

class ParametersAdd extends ParametersEvent {
  final String childId;
  final DateTime date;
  final double? height;
  final double? weight;
  final double? shoeSize;

  const ParametersAdd({
    required this.childId,
    required this.date,
    this.height,
    this.weight,
    this.shoeSize,
  });

  @override
  List<Object?> get props => [childId, date, height, weight, shoeSize];
}

class ParametersUpdate extends ParametersEvent {
  final Parameter parameter;

  const ParametersUpdate(this.parameter);

  @override
  List<Object?> get props => [parameter];
}

class ParametersDelete extends ParametersEvent {
  final String id;
  final String childId;

  const ParametersDelete({required this.id, required this.childId});

  @override
  List<Object?> get props => [id, childId];
}

// State
abstract class ParametersState extends Equatable {
  const ParametersState();

  @override
  List<Object?> get props => [];
}

class ParametersInitial extends ParametersState {}

class ParametersLoading extends ParametersState {}

class ParametersLoaded extends ParametersState {
  final List<Parameter> parameters;

  const ParametersLoaded(this.parameters);

  Parameter? get latestHeight {
    final withHeight = parameters.where((p) => p.height != null).toList();
    if (withHeight.isEmpty) return null;
    return withHeight.first;
  }

  Parameter? get latestWeight {
    final withWeight = parameters.where((p) => p.weight != null).toList();
    if (withWeight.isEmpty) return null;
    return withWeight.first;
  }

  Parameter? get latestShoeSize {
    final withShoe = parameters.where((p) => p.shoeSize != null).toList();
    if (withShoe.isEmpty) return null;
    return withShoe.first;
  }

  @override
  List<Object?> get props => [parameters];
}

class ParametersError extends ParametersState {
  final String message;

  const ParametersError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ParametersBloc extends Bloc<ParametersEvent, ParametersState> {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();

  ParametersBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(ParametersInitial()) {
    on<ParametersLoad>(_onLoad);
    on<ParametersAdd>(_onAdd);
    on<ParametersUpdate>(_onUpdate);
    on<ParametersDelete>(_onDelete);
  }

  Future<void> _onLoad(
    ParametersLoad event,
    Emitter<ParametersState> emit,
  ) async {
    emit(ParametersLoading());
    try {
      final parameters = await _db.getParametersForChild(event.childId);
      emit(ParametersLoaded(parameters));
    } catch (e) {
      emit(ParametersError(e.toString()));
    }
  }

  Future<void> _onAdd(
    ParametersAdd event,
    Emitter<ParametersState> emit,
  ) async {
    try {
      final parameter = Parameter(
        id: _uuid.v4(),
        childId: event.childId,
        date: event.date,
        height: event.height,
        weight: event.weight,
        shoeSize: event.shoeSize,
        createdAt: DateTime.now(),
      );

      await _db.insertParameter(parameter);
      final parameters = await _db.getParametersForChild(event.childId);
      emit(ParametersLoaded(parameters));
    } catch (e) {
      emit(ParametersError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    ParametersUpdate event,
    Emitter<ParametersState> emit,
  ) async {
    try {
      await _db.updateParameter(event.parameter);
      final parameters = await _db.getParametersForChild(
        event.parameter.childId,
      );
      emit(ParametersLoaded(parameters));
    } catch (e) {
      emit(ParametersError(e.toString()));
    }
  }

  Future<void> _onDelete(
    ParametersDelete event,
    Emitter<ParametersState> emit,
  ) async {
    try {
      await _db.deleteParameter(event.id);
      final parameters = await _db.getParametersForChild(event.childId);
      emit(ParametersLoaded(parameters));
    } catch (e) {
      emit(ParametersError(e.toString()));
    }
  }
}
