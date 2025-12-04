import 'package:intl/intl.dart';

class DateUtils {
  /// Returns the ISO week number (1-53) for a given [date].
  static int weekNumber(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final daysToFirstThursday = (firstJan.weekday - DateTime.thursday) % 7;
    final firstThursday = firstJan.add(Duration(days: daysToFirstThursday));
    final diff = date.difference(firstThursday).inDays;
    return (diff ~/ 7) + 1;
  }

  /// Human-readable week label: "Week 45 (03 Nov – 09 Nov 2025)"
  static String weekLabel(DateTime startOfWeek) {
    final end = startOfWeek.add(const Duration(days: 6));
    final fmt = DateFormat('dd MMM');
    return 'Week ${weekNumber(startOfWeek)} (${fmt.format(startOfWeek)} – ${fmt.format(end)} ${startOfWeek.year})';
  }

  /// Human-readable month label: "November 2025"
  static String monthLabel(DateTime date) => DateFormat('MMMM yyyy').format(date);
}