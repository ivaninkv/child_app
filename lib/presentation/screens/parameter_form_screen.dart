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
import '../bloc/parameters/parameters_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';

class ParameterFormScreen extends StatefulWidget {
  final String? parameterId;

  const ParameterFormScreen({super.key, this.parameterId});

  @override
  State<ParameterFormScreen> createState() => _ParameterFormScreenState();
}

class _ParameterFormScreenState extends State<ParameterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _shoeSizeController = TextEditingController();
  final _db = DatabaseHelper.instance;

  DateTime _date = DateTime.now();
  bool _isLoading = false;
  Parameter? _existingParameter;
  List<String> _selectedPhotoIds = [];
  List<Photo> _attachedPhotos = [];

  bool get isEditing => widget.parameterId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadParameter();
    }
  }

  Future<void> _loadParameter() async {
    setState(() => _isLoading = true);
    final param = await _db.getParameter(widget.parameterId!);
    if (param != null) {
      // Load attached photos
      final photos = <Photo>[];
      for (final photoId in param.photoIds) {
        final photo = await _db.getPhoto(photoId);
        if (photo != null) {
          photos.add(photo);
        }
      }

      setState(() {
        _existingParameter = param;
        _date = param.date;
        if (param.height != null)
          _heightController.text = param.height.toString();
        if (param.weight != null)
          _weightController.text = param.weight.toString();
        if (param.shoeSize != null)
          _shoeSizeController.text = param.shoeSize.toString();
        _selectedPhotoIds = List<String>.from(param.photoIds);
        _attachedPhotos = photos;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _shoeSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать' : 'Измерить параметры'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(date_utils.DateUtils.formatDateShort(_date)),
                    trailing: const Icon(Icons.edit),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Рост (см)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final height = double.tryParse(value);
                        if (height == null || height <= 0 || height > 250) {
                          return 'Введите корректный рост';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (кг)',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 200) {
                          return 'Введите корректный вес';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shoeSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Размер ноги',
                      prefixIcon: Icon(Icons.sports_handball),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final size = double.tryParse(value);
                        if (size == null || size <= 0 || size > 50) {
                          return 'Введите корректный размер';
                        }
                      }
                      return null;
                    },
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

      final height = _heightController.text.isNotEmpty
          ? double.tryParse(_heightController.text)
          : null;
      final weight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null;
      final shoeSize = _shoeSizeController.text.isNotEmpty
          ? double.tryParse(_shoeSizeController.text)
          : null;

      if (height == null && weight == null && shoeSize == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите хотя бы один параметр')),
        );
        return;
      }

      if (isEditing && _existingParameter != null) {
        final updatedParam = _existingParameter!.copyWith(
          date: _date,
          height: height,
          weight: weight,
          shoeSize: shoeSize,
          photoIds: _selectedPhotoIds,
        );
        context.read<ParametersBloc>().add(ParametersUpdate(updatedParam));
      } else {
        context.read<ParametersBloc>().add(
          ParametersAdd(
            childId: childId,
            date: _date,
            height: height,
            weight: weight,
            shoeSize: shoeSize,
            photoIds: _selectedPhotoIds,
          ),
        );
      }
      context.read<TimelineBloc>().add(TimelineRefresh(childId));

      if (!isEditing || _existingParameter == null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        context.pop();
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
          await _savePhotoAndAddToParameter(image.path);
        }
      } else {
        // Multiple photos from gallery
        final images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          for (final image in images) {
            await _savePhotoAndAddToParameter(image.path);
          }
        }
      }
    }
  }

  Future<void> _savePhotoAndAddToParameter(String imagePath) async {
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
