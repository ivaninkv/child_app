import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../bloc/photos/photos_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';

class PhotoFormScreen extends StatefulWidget {
  final String? photoId;
  final int? fromTab;

  const PhotoFormScreen({super.key, this.photoId, this.fromTab});

  @override
  State<PhotoFormScreen> createState() => _PhotoFormScreenState();
}

class _PhotoFormScreenState extends State<PhotoFormScreen> {
  final _db = DatabaseHelper.instance;
  final _tagController = TextEditingController();
  final _availableTags = <String>[];

  String? _imagePath;
  DateTime _date = DateTime.now();
  final _selectedTags = <String>[];
  bool _isLoading = false;
  Photo? _existingPhoto;

  bool get isEditing => widget.photoId != null;

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
    if (isEditing) {
      _loadPhoto();
    }
  }

  Future<void> _loadAvailableTags() async {
    final tags = await _db.getAllTags();
    setState(() => _availableTags.addAll(tags));
  }

  Future<void> _loadPhoto() async {
    setState(() => _isLoading = true);
    final photo = await _db.getPhoto(widget.photoId!);
    if (photo != null) {
      setState(() {
        _existingPhoto = photo;
        _imagePath = photo.imagePath;
        _date = photo.date;
        _selectedTags.addAll(photo.tags);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать фото' : 'Добавить фото'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_imagePath == null)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('Нажмите для добавления фото'),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('${_date.day}.${_date.month}.${_date.year}'),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                const Text('Теги'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() => _selectedTags.remove(tag));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'Добавить тег',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        onSubmitted: _addTag,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _addTag(_tagController.text),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_availableTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Доступные теги:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags
                        .where((t) => !_selectedTags.contains(t))
                        .map((tag) {
                          return ActionChip(
                            label: Text(tag),
                            onPressed: () {
                              setState(() => _selectedTags.add(tag));
                            },
                          );
                        })
                        .toList(),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _imagePath == null ? null : _save,
                  child: Text(isEditing ? 'Сохранить' : 'Добавить'),
                ),
              ],
            ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Камера'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() => _imagePath = image.path);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _date = date);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_selectedTags.contains(trimmed)) {
      setState(() {
        _selectedTags.add(trimmed);
        _tagController.clear();
        if (!_availableTags.contains(trimmed)) {
          _availableTags.add(trimmed);
        }
      });
    }
  }

  Future<String?> _generateThumbnail(String imagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final thumbnailDir = Directory('${dir.path}/thumbnails');
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }

    final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final thumbnailPath = '${thumbnailDir.path}/$fileName';

    final result = await FlutterImageCompress.compressAndGetFile(
      imagePath,
      thumbnailPath,
      quality: 70,
      minWidth: 400,
      minHeight: 400,
    );

    return result?.path;
  }

  Future<void> _save() async {
    final appState = context.read<AppBloc>().state;
    if (appState.selectedChild == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сначала выберите ребенка')));
      return;
    }

    if (_imagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите фото')));
      return;
    }

    final childId = appState.selectedChild!.id;
    final isNewPhoto = !isEditing || _existingPhoto == null;

    String? thumbnailPath;
    if (!isEditing || _existingPhoto == null) {
      thumbnailPath = await _generateThumbnail(_imagePath!);
      if (thumbnailPath == null) {
        thumbnailPath = _imagePath;
      }
    }

    if (isEditing && _existingPhoto != null) {
      final updatedPhoto = _existingPhoto!.copyWith(
        date: _date,
        tags: _selectedTags,
      );
      context.read<PhotosBloc>().add(PhotosUpdate(updatedPhoto));
    } else {
      context.read<PhotosBloc>().add(
        PhotosAdd(
          childId: childId,
          imagePath: _imagePath!,
          thumbnailPath: thumbnailPath,
          date: _date,
          tags: _selectedTags,
        ),
      );
    }
    context.read<TimelineBloc>().add(TimelineRefresh(childId));

    if (isNewPhoto) {
      if (mounted) {
        if (widget.fromTab != null) {
          context.go('/?tab=${widget.fromTab}');
        } else {
          context.go('/');
        }
      }
    } else {
      if (widget.fromTab != null) {
        context.go('/?tab=${widget.fromTab}');
      } else {
        context.pop();
      }
    }
  }
}
