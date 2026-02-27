import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/children/children_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';

class ChildFormScreen extends StatefulWidget {
  final String? childId;

  const ChildFormScreen({super.key, this.childId});

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _db = DatabaseHelper.instance;

  DateTime? _birthDate;
  Gender _gender = Gender.male;
  String? _avatarPath;
  bool _isLoading = false;
  Child? _existingChild;

  bool get isEditing => widget.childId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadChild();
    }
  }

  Future<void> _loadChild() async {
    setState(() => _isLoading = true);
    final child = await _db.getChild(widget.childId!);
    if (child != null) {
      setState(() {
        _existingChild = child;
        _nameController.text = child.name;
        _birthDate = child.birthDate;
        _gender = child.gender;
        _avatarPath = child.avatarPath;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать' : 'Добавить ребенка'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarPath != null
                            ? FileImage(File(_avatarPath!))
                            : null,
                        child: _avatarPath == null
                            ? const Icon(Icons.add_a_photo, size: 30)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Нажмите для выбора фото',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите имя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake),
                    title: Text(
                      _birthDate != null
                          ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'
                          : 'Дата рождения *',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickBirthDate,
                  ),
                  const SizedBox(height: 16),
                  const Text('Пол *'),
                  const SizedBox(height: 8),
                  SegmentedButton<Gender>(
                    segments: const [
                      ButtonSegment(
                        value: Gender.male,
                        label: Text('Мальчик'),
                        icon: Icon(Icons.male),
                      ),
                      ButtonSegment(
                        value: Gender.female,
                        label: Text('Девочка'),
                        icon: Icon(Icons.female),
                      ),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (value) {
                      setState(() => _gender = value.first);
                    },
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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _birthDate != null) {
      final isNewChild = !isEditing || _existingChild == null;

      if (isEditing && _existingChild != null) {
        final updatedChild = _existingChild!.copyWith(
          name: _nameController.text,
          birthDate: _birthDate,
          gender: _gender,
          avatarPath: _avatarPath,
        );
        context.read<ChildrenBloc>().add(ChildrenUpdate(updatedChild));
      } else {
        context.read<ChildrenBloc>().add(
          ChildrenAdd(
            name: _nameController.text,
            birthDate: _birthDate!,
            gender: _gender,
            avatarPath: _avatarPath,
          ),
        );
      }
      context.read<AppBloc>().add(AppRefreshChildren());

      if (isNewChild) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        context.pop();
      }
    } else if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите дату рождения')));
    }
  }
}
