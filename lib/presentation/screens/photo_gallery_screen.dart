import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/photos/photos_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final String? childId;

  const PhotoGalleryScreen({super.key, this.childId});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  String? _selectedTag;
  final _allTags = <String>[];
  bool _isSelectionMode = false;
  final _selectedPhotos = <String>{};
  String? _lastChildId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhotos();
    });
  }

  @override
  void didUpdateWidget(covariant PhotoGalleryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _loadPhotos();
    }
  }

  void _loadPhotos() {
    final childId =
        widget.childId ?? context.read<AppBloc>().state.selectedChild?.id;
    if (childId != null && childId != _lastChildId) {
      _lastChildId = childId;
      context.read<PhotosBloc>().add(PhotosLoad(childId));
    }
  }

  void _toggleSelection(String photoId) {
    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
      } else {
        _selectedPhotos.add(photoId);
      }
    });
  }

  void _enterSelectionMode(String photoId) {
    setState(() {
      _isSelectionMode = true;
      _selectedPhotos.add(photoId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPhotos.clear();
    });
  }

  void _deleteSelectedPhotos(List<Photo> photos) {
    if (_selectedPhotos.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить ${_selectedPhotos.length} фото?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final childId = context.read<AppBloc>().state.selectedChild!.id;
              for (final photoId in _selectedPhotos) {
                context.read<PhotosBloc>().add(
                  PhotosDelete(id: photoId, childId: childId),
                );
              }
              context.read<TimelineBloc>().add(TimelineRefresh(childId));
              Navigator.pop(ctx);
              _exitSelectionMode();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('Выбрано: ${_selectedPhotos.length}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    final state = context.read<PhotosBloc>().state;
                    if (state is PhotosLoaded) {
                      _deleteSelectedPhotos(state.photos);
                    }
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text('Фотогалерея'),
              actions: [
                if (_selectedTag != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _selectedTag = null),
                  ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
      body: BlocBuilder<PhotosBloc, PhotosState>(
        builder: (context, state) {
          if (state is PhotosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PhotosLoaded) {
            _allTags.clear();
            _allTags.addAll(state.availableTags);

            var photos = state.photos;
            if (_selectedTag != null) {
              photos = photos
                  .where((p) => p.tags.contains(_selectedTag))
                  .toList();
            }

            if (photos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedTag != null
                          ? 'Нет фото с тегом "$_selectedTag"'
                          : 'Нет фотографий',
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                Column(
                  children: [
                    if (_selectedTag != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Chip(
                          label: Text(_selectedTag!),
                          onDeleted: () => setState(() => _selectedTag = null),
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          return _PhotoThumbnail(
                            photo: photo,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(photo.id);
                              } else {
                                context.go('/photo/viewer/$index?fromTab=1');
                              }
                            },
                            onLongPress: () => _enterSelectionMode(photo.id),
                            isSelected: _selectedPhotos.contains(photo.id),
                            isSelectionMode: _isSelectionMode,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: null,
    );
  }

  void _showFilterDialog() {
    if (_allTags.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет доступных тегов')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Фильтр по тегам', style: TextStyle(fontSize: 18)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: const Text('Все фото'),
                    selected: _selectedTag == null,
                    onTap: () {
                      setState(() => _selectedTag = null);
                      Navigator.pop(context);
                    },
                  ),
                  ..._allTags.map(
                    (tag) => ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text(tag),
                      selected: _selectedTag == tag,
                      onTap: () {
                        setState(() => _selectedTag = tag);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
    required this.isSelected,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = File(photo.thumbnailPath ?? photo.imagePath);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          if (isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.blue
                      : Colors.white.withValues(alpha: 0.7),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
