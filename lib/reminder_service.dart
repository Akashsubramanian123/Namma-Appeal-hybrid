import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Handles scheduling and cancelling RTI deadline local notifications.
class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    'rti_reminders',
    'RTI Deadline Reminders',
    channelDescription: 'Reminds you about RTI response and appeal deadlines.',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  /// Schedules two reminders for an RTI:
  ///   - Day 27: Follow-up nudge before 30-day window closes.
  ///   - Day 57: First Appeal window warning (closes Day 60).
  ///
  /// Returns the list of notification IDs so they can be stored in the DB.
  static Future<List<int>> scheduleRtiReminders({
    required DateTime filingDate,
    required String department,
    required String topic,
  }) async {
    final _notifications = FlutterLocalNotificationsPlugin();
    
    // Unique IDs based on the date
    final int id27 = int.parse("${filingDate.day}${filingDate.month}27");
    final int id57 = int.parse("${filingDate.day}${filingDate.month}57");

    // TEST TIMINGS (15 and 30 seconds)
    final tz.TZDateTime time27 = tz.TZDateTime.now(tz.local).add(const Duration(days: 27));
    final tz.TZDateTime time57 = tz.TZDateTime.now(tz.local).add(const Duration(days: 57));

    // CRITICAL: Android Requires explicit Channel Details and High Priority
    const androidDetails = AndroidNotificationDetails(
      'rti_reminders_channel', // Channel ID
      'RTI Deadlines',         // Channel Name
      channelDescription: 'Reminders for RTI follow-ups and appeals',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    // CRITICAL: exactAllowWhileIdle forces Android to wake up and fire it
    await _notifications.zonedSchedule(
      id27,
      'RTI Follow-up Due!',
      'Time to check on your RTI regarding "$topic".',
      time27,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _notifications.zonedSchedule(
      id57,
      'First Appeal Deadline!',
      'The 57-day window for "$topic" is closing soon.',
      time57,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    return [id27, id57];
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// Generates a stable unique int ID from filing date + day offset.
  static int _uniqueId(DateTime date, int dayOffset) {
    return int.parse(
      '${date.year % 100}${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}$dayOffset',
    );
  }
}
