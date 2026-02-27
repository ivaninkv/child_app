import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/models.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class AppInitialize extends AppEvent {}

class AppSelectChild extends AppEvent {
  final String childId;

  const AppSelectChild(this.childId);

  @override
  List<Object?> get props => [childId];
}

class AppUpdateThemeMode extends AppEvent {
  final ThemeMode themeMode;

  const AppUpdateThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class AppRefreshChildren extends AppEvent {}

// State
class AppState extends Equatable {
  final ThemeMode themeMode;
  final List<Child> children;
  final Child? selectedChild;
  final bool isLoading;
  final String? error;

  const AppState({
    this.themeMode = ThemeMode.system,
    this.children = const [],
    this.selectedChild,
    this.isLoading = false,
    this.error,
  });

  AppState copyWith({
    ThemeMode? themeMode,
    List<Child>? children,
    Child? selectedChild,
    bool? isLoading,
    String? error,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    children,
    selectedChild,
    isLoading,
    error,
  ];
}

// BLoC
class AppBloc extends Bloc<AppEvent, AppState> {
  final DatabaseHelper _db;

  AppBloc({DatabaseHelper? db})
    : _db = db ?? DatabaseHelper.instance,
      super(const AppState()) {
    on<AppInitialize>(_onInitialize);
    on<AppSelectChild>(_onSelectChild);
    on<AppUpdateThemeMode>(_onUpdateThemeMode);
    on<AppRefreshChildren>(_onRefreshChildren);
  }

  Future<void> _onInitialize(
    AppInitialize event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final children = await _db.getAllChildren();

      Child? selectedChild;
      if (children.isNotEmpty) {
        selectedChild = children.first;
      }

      emit(
        state.copyWith(
          children: children,
          selectedChild: selectedChild,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSelectChild(
    AppSelectChild event,
    Emitter<AppState> emit,
  ) async {
    final child = state.children.firstWhere(
      (c) => c.id == event.childId,
      orElse: () => state.children.first,
    );

    emit(state.copyWith(selectedChild: child));
  }

  void _onUpdateThemeMode(AppUpdateThemeMode event, Emitter<AppState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onRefreshChildren(
    AppRefreshChildren event,
    Emitter<AppState> emit,
  ) async {
    try {
      final children = await _db.getAllChildren();

      Child? selectedChild = state.selectedChild;
      if (selectedChild != null) {
        final exists = children.any((c) => c.id == selectedChild!.id);
        if (!exists && children.isNotEmpty) {
          selectedChild = children.first;
        } else if (exists) {
          selectedChild = children.firstWhere((c) => c.id == selectedChild!.id);
        }
      } else if (children.isNotEmpty) {
        selectedChild = children.first;
      }

      emit(state.copyWith(children: children, selectedChild: selectedChild));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
