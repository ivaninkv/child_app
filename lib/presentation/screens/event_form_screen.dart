import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../core/utils/exif_utils.dart';
import '../bloc/events/events_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';

class EventFormScreen extends StatefulWidget {
  final String? eventId;

  const EventFormScreen({super.key, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _db = DatabaseHelper.instance;

  DateTime _date = DateTime.now();
  String? _category;
  bool _isLoading = false;
  Event? _existingEvent;
  List<String> _selectedPhotoIds = [];
  List<Photo> _attachedPhotos = [];

  bool get isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    final event = await _db.getEvent(widget.eventId!);
    if (event != null) {
      // Load attached photos
      final photos = <Photo>[];
      for (final photoId in event.photoIds) {
        final photo = await _db.getPhoto(photoId);
        if (photo != null) {
          photos.add(photo);
        }
      }

      setState(() {
        _existingEvent = event;
        _titleController.text = event.title;
        _descriptionController.text = event.description;
        _date = event.date;
        _category = event.category;
        _selectedPhotoIds = List<String>.from(event.photoIds);
        _attachedPhotos = photos;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать событие' : 'Новое событие'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Заголовок *',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите заголовок';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Описание *',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите описание';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category),
                    title: Text(_category ?? 'Категория'),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: _pickCategory,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(date_utils.DateUtils.formatDateShort(_date)),
                    trailing: const Icon(Icons.edit),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  _buildPhotoAttachmentSection(),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Сохранить' : 'Добавить'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickCategory() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: AppConstants.eventCategories.map((cat) {
            return ListTile(
              title: Text(cat),
              trailing: _category == cat ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, cat),
            );
          }).toList(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _category = result);
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      final childId = context.read<AppBloc>().state.selectedChild!.id;

      if (isEditing && _existingEvent != null) {
        final updatedEvent = _existingEvent!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: _date,
          category: _category,
          photoIds: _selectedPhotoIds,
        );
        context.read<EventsBloc>().add(EventsUpdate(updatedEvent));
        context.read<TimelineBloc>().add(TimelineRefresh(childId));
        context.pop();
      } else {
        context.read<EventsBloc>().add(
          EventsAdd(
            childId: childId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            date: _date,
            category: _category,
            photoIds: _selectedPhotoIds,
          ),
        );
        context.read<TimelineBloc>().add(TimelineRefresh(childId));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Widget _buildPhotoAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Фотографии',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_attachedPhotos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachedPhotos.length,
              itemBuilder: (context, index) {
                final photo = _attachedPhotos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo.thumbnailPath ?? photo.imagePath),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: Colors.white,
                          onPressed: () => _removePhoto(photo.id),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Добавить фото'),
        ),
      ],
    );
  }

  Future<void> _pickPhotos() async {
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
              title: const Text('Галерея (множественный выбор)'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      if (source == ImageSource.camera) {
        // Single photo from camera
        final image = await picker.pickImage(source: source);
        if (image != null) {
          await _savePhotoAndAddToEvent(image.path);
        }
      } else {
        // Multiple photos from gallery
        final images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          for (final image in images) {
            await _savePhotoAndAddToEvent(image.path);
          }
        }
      }
    }
  }

  Future<void> _savePhotoAndAddToEvent(String imagePath) async {
    final appState = context.read<AppBloc>().state;
    if (appState.selectedChild == null) return;

    final childId = appState.selectedChild!.id;
    final thumbnailPath = await _generateThumbnail(imagePath);

    final year = await extractYearFromImage(imagePath);
    final tags = <String>[];
    if (year != null) {
      tags.add(year.toString());
    }

    final photo = Photo(
      id: const Uuid().v4(),
      childId: childId,
      imagePath: imagePath,
      thumbnailPath: thumbnailPath ?? imagePath,
      date: DateTime.now(),
      tags: tags,
      createdAt: DateTime.now(),
    );

    await _db.insertPhoto(photo);

    setState(() {
      _selectedPhotoIds.add(photo.id);
      _attachedPhotos.add(photo);
    });
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

  void _removePhoto(String photoId) {
    setState(() {
      _selectedPhotoIds.remove(photoId);
      _attachedPhotos.removeWhere((photo) => photo.id == photoId);
    });
  }
}
