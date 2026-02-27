import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../bloc/photos/photos_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';

class PhotoViewerScreen extends StatefulWidget {
  final int initialIndex;
  final int? fromTab;

  const PhotoViewerScreen({
    super.key,
    required this.initialIndex,
    this.fromTab,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PhotosBloc, PhotosState>(
        builder: (context, state) {
          if (state is! PhotosLoaded || state.photos.isEmpty) {
            return const Center(
              child: Text(
                'Нет фотографий',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final photos = state.photos;

          return Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showInfo = !_showInfo),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.file(
                          File(photo.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showInfo) _buildInfoPanel(photos),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: AnimatedOpacity(
                    opacity: _showInfo ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              if (widget.fromTab != null) {
                                context.go('/?tab=${widget.fromTab}');
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          Text(
                            '${_currentIndex + 1} / ${photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  final photo = photos[_currentIndex];
                                  Navigator.of(context).pop();
                                  context.go(
                                    '/photo/edit/${photo.id}?fromTab=${widget.fromTab ?? 1}',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                                onPressed: () => _showDeleteDialog(photos),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoPanel(List<Photo> photos) {
    final photo = photos[_currentIndex];
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showInfo ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            32,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${photo.date.day}.${photo.date.month}.${photo.date.year}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (photo.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: photo.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(List<Photo> photos) {
    final photo = photos[_currentIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить фото?'),
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
              context.read<PhotosBloc>().add(
                PhotosDelete(id: photo.id, childId: childId),
              );
              context.read<TimelineBloc>().add(TimelineRefresh(childId));
              Navigator.pop(ctx);
              if (widget.fromTab != null) {
                context.go('/?tab=${widget.fromTab}');
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
