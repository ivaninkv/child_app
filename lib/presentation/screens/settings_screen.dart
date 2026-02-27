import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/app/app_bloc.dart';
import '../bloc/reminders/reminders_bloc.dart';
import '../../core/utils/notification_service.dart';
import '../../data/models/models.dart';
import '../../data/datasources/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper.instance;
  final _notificationService = NotificationService();
  ReminderSettings? _reminderSettings;

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final child = context.read<AppBloc>().state.selectedChild;
    if (child != null) {
      final settings = await _db.getReminderSettingsForChild(child.id);
      if (settings != null) {
        setState(() => _reminderSettings = settings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Внешний вид'),
          BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Тема'),
                subtitle: Text(_getThemeName(state.themeMode)),
                onTap: () => _showThemeDialog(context, state.themeMode),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Напоминания'),
          if (_reminderSettings != null) ...[
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Напоминания о замере'),
              subtitle: Text(
                _reminderSettings!.enabled
                    ? 'Включены (${_reminderSettings!.intervalString})'
                    : 'Выключены',
              ),
              value: _reminderSettings!.enabled,
              onChanged: (value) => _toggleReminder(value),
            ),
            if (_reminderSettings!.enabled)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Периодичность'),
                subtitle: Text(_reminderSettings!.intervalString),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showIntervalDialog,
              ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Время'),
              subtitle: Text(_reminderSettings!.timeString),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showTimeDialog,
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Настроить напоминания'),
              onTap: _createReminderSettings,
            ),
          const Divider(),
          const _SectionHeader(title: 'Дети'),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Управление профилями'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/children'),
          ),
          const Divider(),
          const _SectionHeader(title: 'О приложении'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Child App'),
            subtitle: Text('Версия 1.0.0'),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Системная';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Светлая'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                context.read<AppBloc>().add(AppUpdateThemeMode(value!));
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Темная'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                context.read<AppBloc>().add(AppUpdateThemeMode(value!));
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Системная'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                context.read<AppBloc>().add(AppUpdateThemeMode(value!));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReminder(bool value) async {
    final child = context.read<AppBloc>().state.selectedChild;
    if (child != null && _reminderSettings != null) {
      final updated = _reminderSettings!.copyWith(enabled: value);
      await _db.updateReminderSettings(updated);

      if (value) {
        await _notificationService.scheduleReminder(
          settings: updated,
          childName: child.name,
        );
      } else {
        await _notificationService.cancelReminder(child.id);
      }

      setState(() => _reminderSettings = updated);
    }
  }

  void _showIntervalDialog() async {
    final result = await showDialog<ReminderInterval>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Периодичность'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReminderInterval.values.map((interval) {
            return RadioListTile<ReminderInterval>(
              title: Text(_getIntervalString(interval)),
              value: interval,
              groupValue: _reminderSettings!.interval,
              onChanged: (value) => Navigator.pop(ctx, value),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      final updated = _reminderSettings!.copyWith(interval: result);
      await _db.updateReminderSettings(updated);

      final child = context.read<AppBloc>().state.selectedChild;
      if (child != null && updated.enabled) {
        await _notificationService.scheduleReminder(
          settings: updated,
          childName: child.name,
        );
      }

      setState(() => _reminderSettings = updated);
    }
  }

  void _showTimeDialog() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderSettings!.hour,
        minute: _reminderSettings!.minute,
      ),
    );

    if (result != null) {
      final updated = _reminderSettings!.copyWith(
        hour: result.hour,
        minute: result.minute,
      );
      await _db.updateReminderSettings(updated);

      final child = context.read<AppBloc>().state.selectedChild;
      if (child != null && updated.enabled) {
        await _notificationService.scheduleReminder(
          settings: updated,
          childName: child.name,
        );
      }

      setState(() => _reminderSettings = updated);
    }
  }

  String _getIntervalString(ReminderInterval interval) {
    switch (interval) {
      case ReminderInterval.weekly:
        return 'Раз в неделю';
      case ReminderInterval.biweekly:
        return 'Раз в 2 недели';
      case ReminderInterval.monthly:
        return 'Раз в месяц';
    }
  }

  Future<void> _createReminderSettings() async {
    final child = context.read<AppBloc>().state.selectedChild;
    if (child != null) {
      final settings = ReminderSettings(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        childId: child.id,
        interval: ReminderInterval.monthly,
        hour: 10,
        minute: 0,
        enabled: true,
      );

      await _db.insertReminderSettings(settings);
      await _notificationService.scheduleReminder(
        settings: settings,
        childName: child.name,
      );

      setState(() => _reminderSettings = settings);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
