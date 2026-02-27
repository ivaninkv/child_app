import 'package:equatable/equatable.dart';

enum ReminderInterval { weekly, biweekly, monthly }

class ReminderSettings extends Equatable {
  final String id;
  final String childId;
  final ReminderInterval interval;
  final int hour;
  final int minute;
  final bool enabled;
  final DateTime? lastNotified;

  const ReminderSettings({
    required this.id,
    required this.childId,
    required this.interval,
    required this.hour,
    required this.minute,
    required this.enabled,
    this.lastNotified,
  });

  ReminderSettings copyWith({
    String? id,
    String? childId,
    ReminderInterval? interval,
    int? hour,
    int? minute,
    bool? enabled,
    DateTime? lastNotified,
  }) {
    return ReminderSettings(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      interval: interval ?? this.interval,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      lastNotified: lastNotified ?? this.lastNotified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'interval': interval.name,
      'hour': hour,
      'minute': minute,
      'enabled': enabled ? 1 : 0,
      'last_notified': lastNotified?.millisecondsSinceEpoch,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      interval: ReminderInterval.values.firstWhere(
        (e) => e.name == map['interval'],
      ),
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      enabled: (map['enabled'] as int) == 1,
      lastNotified: map['last_notified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_notified'] as int)
          : null,
    );
  }

  int get intervalDays {
    switch (interval) {
      case ReminderInterval.weekly:
        return 7;
      case ReminderInterval.biweekly:
        return 14;
      case ReminderInterval.monthly:
        return 30;
    }
  }

  String get intervalString {
    switch (interval) {
      case ReminderInterval.weekly:
        return 'Раз в неделю';
      case ReminderInterval.biweekly:
        return 'Раз в 2 недели';
      case ReminderInterval.monthly:
        return 'Раз в месяц';
    }
  }

  String get timeString {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    childId,
    interval,
    hour,
    minute,
    enabled,
    lastNotified,
  ];
}
