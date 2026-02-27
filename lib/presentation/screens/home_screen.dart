import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/app/app_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';
import '../widgets/timeline_card.dart';
import 'photo_gallery_screen.dart';
import 'growth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final DatabaseHelper _db = DatabaseHelper.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        if (appState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (appState.children.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Child App')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.child_care, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    Text(
                      'Добро пожаловать!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Добавьте первого ребенка, чтобы начать записывать важные моменты его жизни',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/child/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить ребенка'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final selectedChild = appState.selectedChild!;

        return Scaffold(
          appBar: AppBar(
            title: _currentIndex == 0
                ? _buildSearchField()
                : _buildChildSelector(appState),
            actions: [
              if (_currentIndex != 0)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.go('/settings'),
                ),
            ],
          ),
          body: _buildBody(selectedChild),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.timeline), label: 'Лента'),
              NavigationDestination(
                icon: Icon(Icons.photo_library),
                label: 'Фото',
              ),
              NavigationDestination(
                icon: Icon(Icons.straighten),
                label: 'Параметры',
              ),
            ],
          ),
          floatingActionButton: _buildFab(context, selectedChild),
        );
      },
    );
  }

  Widget _buildChildSelector(AppState state) {
    return DropdownButton<String>(
      value: state.selectedChild?.id,
      underline: const SizedBox(),
      items: state.children.map((child) {
        return DropdownMenuItem<String>(
          value: child.id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: child.avatarPath != null
                    ? FileImage(File(child.avatarPath!))
                    : null,
                child: child.avatarPath == null
                    ? Text(child.name[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 8),
              Text(child.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          context.read<AppBloc>().add(AppSelectChild(value));
        }
      },
    );
  }

  Widget _buildBody(Child child) {
    switch (_currentIndex) {
      case 0:
        return _TimelineTab(childId: child.id, searchQuery: _searchQuery);
      case 1:
        return _PhotosTab(childId: child.id);
      case 2:
        return _ParametersTab(childId: child.id);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 40,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Поиск...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFab(BuildContext context, Child child) {
    return FloatingActionButton(
      onPressed: () {
        switch (_currentIndex) {
          case 0:
            _showAddEventDialog(context, child);
            break;
          case 1:
            context.go('/photo/add');
            break;
          case 2:
            context.go('/parameter/add');
            break;
        }
      },
      child: const Icon(Icons.add),
    );
  }

  void _showAddEventDialog(BuildContext context, Child child) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('Текстовая запись'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/event/add');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Добавить фото'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/photo/add');
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Замерить параметры'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/parameter/add');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineTab extends StatefulWidget {
  final String childId;
  final String searchQuery;

  const _TimelineTab({required this.childId, this.searchQuery = ''});

  @override
  State<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<_TimelineTab> {
  @override
  void initState() {
    super.initState();
    context.read<TimelineBloc>().add(TimelineLoad(widget.childId));
  }

  @override
  void didUpdateWidget(covariant _TimelineTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      context.read<TimelineBloc>().add(TimelineLoad(widget.childId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineBloc, TimelineState>(
      builder: (context, state) {
        if (state is TimelineLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TimelineLoaded) {
          final query = widget.searchQuery.toLowerCase();
          final filteredItems = query.isEmpty
              ? state.items
              : state.items.where((item) {
                  if (item.event != null) {
                    final event = item.event!;
                    return event.title.toLowerCase().contains(query) ||
                        event.description.toLowerCase().contains(query) ||
                        (event.category?.toLowerCase().contains(query) ??
                            false);
                  }
                  if (item.photo != null) {
                    final photo = item.photo!;
                    return photo.tags.any(
                      (tag) => tag.toLowerCase().contains(query),
                    );
                  }
                  return false;
                }).toList();

          if (filteredItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timeline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    query.isEmpty ? 'Пока нет записей' : 'Ничего не найдено',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (query.isEmpty)
                    TextButton(
                      onPressed: () => context.go('/event/add'),
                      child: const Text('Добавить первое событие'),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TimelineBloc>().add(TimelineRefresh(widget.childId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return TimelineCard(
                  item: item,
                  onTap: () {
                    final typeStr = item.type.name;
                    context.go('/timeline/$typeStr/${item.id}');
                  },
                );
              },
            ),
          );
        }

        if (state is TimelineError) {
          return Center(child: Text('Ошибка: ${state.message}'));
        }

        return const SizedBox();
      },
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final String childId;

  const _PhotosTab({required this.childId});

  @override
  Widget build(BuildContext context) {
    return const PhotoGalleryScreen();
  }
}

class _ParametersTab extends StatelessWidget {
  final String childId;

  const _ParametersTab({required this.childId});

  @override
  Widget build(BuildContext context) {
    return const GrowthScreen();
  }
}
