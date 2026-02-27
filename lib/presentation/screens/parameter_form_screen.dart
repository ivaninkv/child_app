import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      setState(() {
        _existingParameter = param;
        _date = param.date;
        if (param.height != null)
          _heightController.text = param.height.toString();
        if (param.weight != null)
          _weightController.text = param.weight.toString();
        if (param.shoeSize != null)
          _shoeSizeController.text = param.shoeSize.toString();
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
                    title: Text('${_date.day}.${_date.month}.${_date.year}'),
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
          ),
        );
      }
      context.read<TimelineBloc>().add(TimelineRefresh(childId));
      context.pop();
    }
  }
}
