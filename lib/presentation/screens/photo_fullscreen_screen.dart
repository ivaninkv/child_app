import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';
import '../bloc/photos/photos_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';

class PhotoFullscreenScreen extends StatefulWidget {
  final String photoId;

  const PhotoFullscreenScreen({super.key, required this.photoId});

  @override
  State<PhotoFullscreenScreen> createState() => _PhotoFullscreenScreenState();
}

class _PhotoFullscreenScreenState extends State<PhotoFullscreenScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper.instance;
  final _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _showInfo = false;
  Photo? _photo;
  bool _isLoading = true;
  bool _isZoomed = false;
  final _targetScale = 2.5;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadPhoto() async {
    final photo = await _db.getPhoto(widget.photoId);
    if (photo != null && mounted) {
      setState(() {
        _photo = photo;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleDoubleTap(TapDownDetails details, Size size) {
    _animationController.stop();

    final Matrix4 endMatrix;
    if (_isZoomed) {
      endMatrix = Matrix4.identity();
      _isZoomed = false;
    } else {
      endMatrix = _getZoomMatrix(details.localPosition, size);
      _isZoomed = true;
    }

    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: endMatrix,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });

    _animationController.forward(from: 0);
  }

  Matrix4 _getZoomMatrix(Offset tapPosition, Size size) {
    final scale = _targetScale;
    final x = tapPosition.dx;
    final y = tapPosition.dy;

    // Translate to center zoom at tap position
    // Formula: translate(tapX, tapY) * scale * translate(-tapX, -tapY)
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_photo == null) {
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

    return _buildContent(_photo!);
  }

  Widget _buildContent(Photo photo) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTap: () => setState(() => _showInfo = !_showInfo),
                onDoubleTapDown: (details) => _handleDoubleTap(details, size),
                child: InteractiveViewer(
                  transformationController: _transformationController,
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
          ),
          if (_showInfo) _buildInfoPanel(photo),
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go('/photo/edit/${photo.id}?fromTab=0');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _showDeleteDialog(photo),
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

  Widget _buildInfoPanel(Photo photo) {
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
                '${photo.date.day.toString().padLeft(2, '0')}.${photo.date.month.toString().padLeft(2, '0')}.${photo.date.year}',
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

  void _showDeleteDialog(Photo photo) {
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
              Navigator.of(context).pop();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
