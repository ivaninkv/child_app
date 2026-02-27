import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      setState(() {
        _existingEvent = event;
        _titleController.text = event.title;
        _descriptionController.text = event.description;
        _date = event.date;
        _category = event.category;
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
                    title: Text('${_date.day}.${_date.month}.${_date.year}'),
                    trailing: const Icon(Icons.edit),
                    onTap: _pickDate,
                  ),
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
      final isNewEvent = !isEditing || _existingEvent == null;

      if (isEditing && _existingEvent != null) {
        final updatedEvent = _existingEvent!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          date: _date,
          category: _category,
        );
        context.read<EventsBloc>().add(EventsUpdate(updatedEvent));
      } else {
        context.read<EventsBloc>().add(
          EventsAdd(
            childId: childId,
            title: _titleController.text,
            description: _descriptionController.text,
            date: _date,
            category: _category,
          ),
        );
      }
      context.read<TimelineBloc>().add(TimelineRefresh(childId));

      if (isNewEvent) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        context.pop();
      }
    }
  }
}
