import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ru_RU').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd.MM.yyyy', 'ru_RU').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy, HH:mm', 'ru_RU').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Сегодня';
    } else if (difference == 1) {
      return 'Вчера';
    } else if (difference < 7) {
      return DateFormat('EEEE', 'ru_RU').format(date);
    } else {
      return formatDate(date);
    }
  }

  static String formatAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;

    if (days < 30) {
      return '$days дней';
    } else if (days < 365) {
      final months = days ~/ 30;
      return '$months месяцев';
    } else {
      final years = days ~/ 365;
      final remainingMonths = (days % 365) ~/ 30;
      if (remainingMonths == 0) {
        return '$years лет';
      }
      return '$years лет $remainingMonths месяцев';
    }
  }
}
