import 'package:flutter/material.dart';

class WorkSchedule {
  static const int slotMinutes = 30;
  static const int workStartHour = 8;
  static const int workEndHour = 21;

  static List<DateTime> generateSlotsForLocalDate(DateTime localDate) {
    final date = DateTime(localDate.year, localDate.month, localDate.day);

    final start = DateTime(date.year, date.month, date.day, workStartHour, 0);
    final end = DateTime(date.year, date.month, date.day, workEndHour, 0);

    final slots = <DateTime>[];
    var cursor = start;
    while (cursor.isBefore(end)) {
      slots.add(cursor);
      cursor = cursor.add(const Duration(minutes: slotMinutes));
    }
    return slots;
  }

  static String formatSlot(DateTime localSlotStart) {
    final h = localSlotStart.hour.toString().padLeft(2, '0');
    final m = localSlotStart.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay getWorkStart() => const TimeOfDay(hour: workStartHour, minute: 0);
  static TimeOfDay getWorkEnd() => const TimeOfDay(hour: workEndHour, minute: 0);
}

