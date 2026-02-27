import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/children/children_bloc.dart';
import '../bloc/app/app_bloc.dart';
import '../../data/models/models.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дети')),
      body: BlocBuilder<ChildrenBloc, ChildrenState>(
        builder: (context, state) {
          if (state is ChildrenLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChildrenLoaded) {
            if (state.children.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.child_care, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Нет детей'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/child/add'),
                      child: const Text('Добавить ребенка'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.children.length,
              itemBuilder: (context, index) {
                final child = state.children[index];
                return _ChildCard(child: child);
              },
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/child/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: child.avatarPath != null
              ? FileImage(File(child.avatarPath!))
              : null,
          child: child.avatarPath == null
              ? Text(
                  child.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
        title: Text(child.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Возраст: ${child.ageString}'),
            Text('Пол: ${child.gender == Gender.male ? 'Мальчик' : 'Девочка'}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              context.go('/child/edit/${child.id}');
            } else if (value == 'delete') {
              _showDeleteDialog(context, child);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Child child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить ребенка?'),
        content: Text('Все данные о ${child.name} будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChildrenBloc>().add(ChildrenDelete(child.id));
              context.read<AppBloc>().add(AppRefreshChildren());
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
