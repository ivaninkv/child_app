import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/photos/photos_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  String? _selectedTag;
  final _allTags = <String>[];

  @override
  void initState() {
    super.initState();
    final childId = context.read<AppBloc>().state.selectedChild?.id;
    if (childId != null) {
      context.read<PhotosBloc>().add(PhotosLoad(childId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фотогалерея'),
        actions: [
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
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.go('/photo/add'),
                      child: const Text('Добавить фото'),
                    ),
                  ],
                ),
              );
            }

            return Column(
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
                        onTap: () => _showPhotoDetail(photo),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/photo/add'),
        child: const Icon(Icons.add_a_photo),
      ),
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

  void _showPhotoDetail(Photo photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(photo.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${photo.date.day}.${photo.date.month}.${photo.date.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (photo.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: photo.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Закрыть'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/timeline/photo/${photo.id}');
                        },
                        child: const Text('Подробнее'),
                      ),
                    ],
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

  const _PhotoThumbnail({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(photo.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }
}
