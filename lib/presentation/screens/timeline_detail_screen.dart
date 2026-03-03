import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../bloc/timeline/timeline_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/models.dart';

class TimelineDetailScreen extends StatefulWidget {
  final String type;
  final String id;

  const TimelineDetailScreen({super.key, required this.type, required this.id});

  @override
  State<TimelineDetailScreen> createState() => _TimelineDetailScreenState();
}

class _TimelineDetailScreenState extends State<TimelineDetailScreen> {
  final _db = DatabaseHelper.instance;
  TimelineItem? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    TimelineItemType type;
    switch (widget.type) {
      case 'event':
        type = TimelineItemType.event;
        break;
      case 'photo':
        type = TimelineItemType.photo;
        break;
      case 'parameter':
        type = TimelineItemType.parameter;
        break;
      default:
        return;
    }

    dynamic data;
    switch (type) {
      case TimelineItemType.event:
        data = await _db.getEvent(widget.id);
        break;
      case TimelineItemType.photo:
        data = await _db.getPhoto(widget.id);
        break;
      case TimelineItemType.parameter:
        data = await _db.getParameter(widget.id);
        break;
    }

    if (data != null && mounted) {
      setState(() {
        _item = TimelineItem(
          id: widget.id,
          type: type,
          date: data.date,
          childId: data.childId,
          event: type == TimelineItemType.event ? data : null,
          photo: type == TimelineItemType.photo ? data : null,
          parameter: type == TimelineItemType.parameter ? data : null,
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Запись не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: _buildContent(),
    );
  }

  String _getTitle() {
    switch (_item!.type) {
      case TimelineItemType.event:
        return 'Событие';
      case TimelineItemType.photo:
        return 'Фотография';
      case TimelineItemType.parameter:
        return 'Параметры';
    }
  }

  Widget _buildContent() {
    switch (_item!.type) {
      case TimelineItemType.event:
        return _buildEventContent();
      case TimelineItemType.photo:
        return _buildPhotoContent();
      case TimelineItemType.parameter:
        return _buildParameterContent();
    }
  }

  Widget _buildEventContent() {
    final event = _item!.event!;
    return FutureBuilder<List<Photo>>(
      future: _loadAttachedPhotos(event.photoIds),
      builder: (context, snapshot) {
        final attachedPhotos = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (event.category != null) Chip(label: Text(event.category!)),
            const SizedBox(height: 16),
            Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Дата: ${date_utils.DateUtils.formatDateShort(event.date)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(event.description),
            if (attachedPhotos.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Прикрепленные фото',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = attachedPhotos[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          final photoIds = attachedPhotos
                              .map((p) => p.id)
                              .join(',');
                          context.push(
                            '/photo/view/${photo.id}?eventId=${event.id}&photoIds=$photoIds',
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(photo.thumbnailPath ?? photo.imagePath),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 32),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<List<Photo>> _loadAttachedPhotos(List<String> photoIds) async {
    final photos = <Photo>[];
    for (final photoId in photoIds) {
      final photo = await _db.getPhoto(photoId);
      if (photo != null) {
        photos.add(photo);
      }
    }
    return photos;
  }

  Widget _buildPhotoContent() {
    final photo = _item!.photo!;
    return ListView(
      children: [
        Image.file(
          File(photo.imagePath),
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.broken_image, size: 64)),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Дата: ${date_utils.DateUtils.formatDateShort(photo.date)}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (photo.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Теги:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: photo.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParameterContent() {
    final param = _item!.parameter!;
    return FutureBuilder<List<Photo>>(
      future: _loadAttachedPhotos(param.photoIds),
      builder: (context, snapshot) {
        final attachedPhotos = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Дата: ${date_utils.DateUtils.formatDateShort(param.date)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (param.height != null)
              _buildMetricCard('Рост', '${param.height} см', Icons.height),
            if (param.weight != null)
              _buildMetricCard(
                'Вес',
                '${param.weight} кг',
                Icons.monitor_weight,
              ),
            if (param.shoeSize != null)
              _buildMetricCard(
                'Размер ноги',
                param.shoeSize.toString(),
                Icons.sports_handball,
              ),
            if (attachedPhotos.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Прикрепленные фото',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = attachedPhotos[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          final photoIds = attachedPhotos
                              .map((p) => p.id)
                              .join(',');
                          context.push(
                            '/photo/view/${photo.id}?eventId=${param.id}&photoIds=$photoIds',
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(photo.thumbnailPath ?? photo.imagePath),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 32),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(label),
        subtitle: Text(value, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  void _edit() {
    switch (_item!.type) {
      case TimelineItemType.event:
        context.go('/event/edit/${_item!.id}');
        break;
      case TimelineItemType.photo:
        context.go('/photo/edit/${_item!.id}?fromTab=0');
        break;
      case TimelineItemType.parameter:
        context.go('/parameter/edit/${_item!.id}');
        break;
    }
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final childId = context.read<AppBloc>().state.selectedChild!.id;
              context.read<TimelineBloc>().add(
                TimelineDeleteEvent(
                  id: _item!.id,
                  type: _item!.type,
                  childId: childId,
                ),
              );
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
