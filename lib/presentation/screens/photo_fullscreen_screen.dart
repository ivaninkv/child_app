import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/datasources/database_helper.dart';
import '../bloc/photos/photos_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';

class PhotoFullscreenScreen extends StatefulWidget {
  final String photoId;
  final String? eventId;
  final List<String> photoIds;

  const PhotoFullscreenScreen({
    super.key,
    required this.photoId,
    this.eventId,
    this.photoIds = const [],
  });

  @override
  State<PhotoFullscreenScreen> createState() => _PhotoFullscreenScreenState();
}

class _PhotoFullscreenScreenState extends State<PhotoFullscreenScreen> {
  final _db = DatabaseHelper.instance;
  late PageController _pageController;
  bool _showInfo = false;
  bool _isLoading = true;
  final _targetScale = 2.5;
  int _currentPhotoIndex = 0;
  List<Photo> _photos = [];
  final Map<int, TransformationController> _transformationControllers = {};
  final Map<int, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    // Load all photos for the event if photoIds are provided
    if (widget.photoIds.isNotEmpty) {
      final photos = <Photo>[];
      for (final photoId in widget.photoIds) {
        final photo = await _db.getPhoto(photoId);
        if (photo != null) {
          photos.add(photo);
        }
      }
      setState(() {
        _photos = photos;
        _currentPhotoIndex = photos.indexWhere((p) => p.id == widget.photoId);
        if (_currentPhotoIndex == -1) _currentPhotoIndex = 0;
        _isLoading = false;
      });
      _pageController = PageController(initialPage: _currentPhotoIndex);
    } else {
      // Load single photo
      final photo = await _db.getPhoto(widget.photoId);
      if (photo != null && mounted) {
        setState(() {
          _photos = [photo];
          _currentPhotoIndex = 0;
          _isLoading = false;
        });
        _pageController = PageController(initialPage: 0);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  TransformationController _getController(int index) {
    if (!_transformationControllers.containsKey(index)) {
      _transformationControllers[index] = TransformationController();
    }
    return _transformationControllers[index]!;
  }

  AnimationController _getAnimationController(int index) {
    if (!_animationControllers.containsKey(index)) {
      _animationControllers[index] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: Navigator.of(context),
      );
    }
    return _animationControllers[index]!;
  }

  void _handleDoubleTap(int index, TapDownDetails details, Size size) {
    final controller = _getController(index);
    final animationController = _getAnimationController(index);
    animationController.stop();

    final Matrix4 matrix = controller.value;
    final double currentScale = matrix.getMaxScaleOnAxis();

    final Matrix4 endMatrix;
    if (currentScale > 1.1) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = _getZoomMatrix(details.localPosition, size);
    }

    final animation = Matrix4Tween(begin: controller.value, end: endMatrix)
        .animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
        );

    animation.addListener(() {
      controller.value = animation.value;
    });

    animationController.forward(from: 0);
  }

  Matrix4 _getZoomMatrix(Offset tapPosition, Size size) {
    final scale = _targetScale;
    final x = tapPosition.dx;
    final y = tapPosition.dy;

    // Translate to center zoom at tap position
    final translateX = x * (1 - scale);
    final translateY = y * (1 - scale);

    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(2, 2, 1.0);
    matrix.setEntry(0, 3, translateX);
    matrix.setEntry(1, 3, translateY);
    return matrix;
  }

  void _goBack() {
    // Use pop() to return to the previous screen (event detail)
    context.pop();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformationControllers.values) {
      controller.dispose();
    }
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_photos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Фото не найдено',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Назад',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showInfo = !_showInfo),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onDoubleTapDown: (details) =>
                          _handleDoubleTap(index, details, size),
                      child: InteractiveViewer(
                        transformationController: _getController(index),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_showInfo) _buildInfoPanel(),
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
                        onPressed: _goBack,
                      ),
                      Text(
                        '${_currentPhotoIndex + 1} / ${_photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              final photo = _photos[_currentPhotoIndex];
                              // Return to event detail screen after editing
                              final returnRoute = widget.eventId != null
                                  ? '/timeline/event/${widget.eventId}'
                                  : null;
                              if (returnRoute != null) {
                                context.go(
                                  '/photo/edit/${photo.id}?fromTab=0&returnRoute=$returnRoute',
                                );
                              } else {
                                _goBack();
                                context.go('/photo/edit/${photo.id}?fromTab=0');
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _showDeleteDialog(),
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
      ),
    );
  }

  Widget _buildInfoPanel() {
    final photo = _photos[_currentPhotoIndex];
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
                date_utils.DateUtils.formatDateShort(photo.date),
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

  void _showDeleteDialog() {
    final photo = _photos[_currentPhotoIndex];
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
              context.pop();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
