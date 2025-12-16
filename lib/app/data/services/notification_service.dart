import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize timezone
      tzdata.initializeTimeZones();
      // Set default to Asia/Jakarta (WIB/UTC+7)
      // User can modify this to their timezone if needed
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        debugPrint('[NotificationService] Timezone set to: Asia/Jakarta');
      } catch (e) {
        debugPrint('[NotificationService] Failed to set timezone: $e');
      }

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      final InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings);

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // For Android 13+
      final notificationStatus = await Permission.notification.request();

      return notificationStatus.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if notification permissions are granted
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      debugPrint('[NotificationService] Permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('[NotificationService] Error checking permission: $e');
      return false;
    }
  }

  /// Schedule notification for a specific task
  ///
  /// [taskId] - Unique identifier for the task
  /// [taskTitle] - Title of the task
  /// [taskDescription] - Description of the task
  /// [scheduledDateTime] - When the task is scheduled
  /// [reminderMinutesBefore] - How many minutes before to remind (e.g., 15)
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required String taskDescription,
    required DateTime scheduledDateTime,
    required int reminderMinutesBefore,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      debugPrint(
        '[NotificationService] scheduleTaskReminder called:'
        '\n  - taskId: $taskId'
        '\n  - taskTitle: $taskTitle'
        '\n  - scheduledDateTime: ${scheduledDateTime.toString()}'
        '\n  - reminderMinutesBefore: $reminderMinutesBefore'
        '\n  - currentTime: ${DateTime.now().toString()}',
      );

      final reminderDateTime = scheduledDateTime.subtract(
        Duration(minutes: reminderMinutesBefore),
      );

      debugPrint(
        '[NotificationService] reminderDateTime: ${reminderDateTime.toString()}'
        '\n  - isAfter(now)? ${reminderDateTime.isAfter(DateTime.now())}',
      );

      // Only schedule if reminder time is in the future
      if (reminderDateTime.isAfter(DateTime.now())) {
        final tzScheduledDateTime = tz.TZDateTime.from(
          reminderDateTime,
          tz.local,
        );

        await _localNotifications.zonedSchedule(
          taskId, // Use task ID as notification ID
          'Pengingat: $taskTitle',
          taskDescription,
          tzScheduledDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Pengingat Tugas',
              channelDescription:
                  'Notifikasi pengingat untuk tugas yang akan datang',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('reminder'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'reminder.wav',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        debugPrint(
          '[NotificationService] ✓ Scheduled task reminder:'
          '\n  - Task ID: $taskId'
          '\n  - Title: $taskTitle'
          '\n  - Scheduled: ${reminderDateTime.toString()}'
          '\n  - Reminder Before: $reminderMinutesBefore min',
        );
      } else {
        debugPrint(
          '[NotificationService] ✗ Skipped scheduling task $taskId'
          '\n  - Reminder time: ${reminderDateTime.toString()}'
          '\n  - Current time: ${DateTime.now().toString()}'
          '\n  - Reason: Reminder time is in the past',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Cancel notification for a specific task
  Future<void> cancelTaskReminder(int taskId) async {
    try {
      await _localNotifications.cancel(taskId);
      debugPrint('Cancelled reminder for task $taskId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('Cancelled all reminders');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Show test notification (for debugging)
  Future<void> showTestNotification() async {
    try {
      await _localNotifications.show(
        9999,
        'Test Notification',
        'Notifikasi sistem berfungsi dengan baik!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Pengingat Tugas',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }
}
