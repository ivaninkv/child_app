import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../bloc/photos/photos_bloc.dart';
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';

class PhotoFormScreen extends StatefulWidget {
  final String photoId;
  final int? fromTab;
  final String? returnRoute;

  const PhotoFormScreen({
    super.key,
    required this.photoId,
    this.fromTab,
    this.returnRoute,
  });

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

  bool get isEditing => true;

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
    _loadPhoto();
  }

  Future<void> _loadAvailableTags() async {
    final tags = await _db.getAllTags();
    setState(() => _availableTags.addAll(tags));
  }

  Future<void> _loadPhoto() async {
    setState(() => _isLoading = true);
    final photo = await _db.getPhoto(widget.photoId);
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
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        if (widget.returnRoute != null) {
          context.go(widget.returnRoute!);
          return false;
        } else if (widget.fromTab != null) {
          context.go('/?tab=${widget.fromTab}');
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Редактировать фото' : 'Добавить фото'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(date_utils.DateUtils.formatDateShort(_date)),
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
                          onSubmitted: (tag) {
                            if (tag.isNotEmpty &&
                                !_selectedTags.contains(tag)) {
                              setState(() => _selectedTags.add(tag));
                              _tagController.clear();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final tag = _tagController.text;
                          if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                            setState(() => _selectedTags.add(tag));
                            _tagController.clear();
                          }
                        },
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
                    onPressed: _save,
                    child: const Text('Сохранить'),
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
    if (_existingPhoto == null) return;

    final childId = context.read<AppBloc>().state.selectedChild!.id;

    final updatedPhoto = _existingPhoto!.copyWith(
      date: _date,
      tags: _selectedTags,
    );
    context.read<PhotosBloc>().add(PhotosUpdate(updatedPhoto));
    context.read<TimelineBloc>().add(TimelineRefresh(childId));

    if (widget.returnRoute != null) {
      context.go(widget.returnRoute!);
    } else if (widget.fromTab != null) {
      context.go('/?tab=${widget.fromTab}');
    } else {
      context.pop();
    }
  }
}
