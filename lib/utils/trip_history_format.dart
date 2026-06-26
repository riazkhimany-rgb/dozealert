abstract final class TripHistoryFormat {
  static String friendlyTimestamp(DateTime value, {DateTime? reference}) {
    final local = value.toLocal();
    final now = (reference ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final valueDay = DateTime(local.year, local.month, local.day);
    final dayDiff = today.difference(valueDay).inDays;
    final time = _formatTime(local);

    if (dayDiff == 0) {
      return 'Today $time';
    }
    if (dayDiff == 1) {
      return 'Yesterday $time';
    }
    if (dayDiff < 7) {
      return '${_weekdayName(local.weekday)} $time';
    }
    if (local.year == now.year) {
      return '${_monthDay(local)} $time';
    }
    return '${_monthDay(local, includeYear: true)} $time';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

  static String _weekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '',
    };
  }

  static String _monthDay(DateTime value, {bool includeYear = false}) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[value.month - 1];
    if (includeYear) {
      return '$month ${value.day}, ${value.year}';
    }
    return '$month ${value.day}';
  }
}
