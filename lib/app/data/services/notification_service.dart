import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Top-level background message handler for Firebase Cloud Messaging
/// Must be a top-level function to work properly
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM Background] Handling background message: ${message.notification?.title}',
  );
  // You can handle background messages here
  // Note: At this point, the app is in the background and the UI context is not available
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

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

      // Initialize Firebase Cloud Messaging
      await _initializeFirebaseMessaging();

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      return false;
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for notifications
      final NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint(
        '[FCM] Notification settings: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCM] User granted notification permissions');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('[FCM] User granted provisional notification permissions');
      } else {
        debugPrint('[FCM] User declined or has not yet granted permissions');
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      debugPrint('[FCM] FCM Token: $token');

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        // TODO: Save the new token to your backend
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[FCM] Received foreground message: ${message.notification?.title}',
        );
        _handleRemoteMessage(message);
      });

      // Handle background message
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle when app is terminated and user taps notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App opened from terminated state via notification');
        _handleRemoteMessage(initialMessage);
      }

      // Handle when app is in background and user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] App opened from background via notification');
        _handleRemoteMessage(message);
      });

      debugPrint('[FCM] Firebase Cloud Messaging initialized successfully');
    } catch (e) {
      debugPrint('[FCM] Error initializing Firebase Cloud Messaging: $e');
    }
  }

  /// Handle incoming remote messages
  void _handleRemoteMessage(RemoteMessage message) {
    try {
      final notification = message.notification;
      final data = message.data;

      debugPrint('[FCM] Handling message:');
      debugPrint('[FCM]   Title: ${notification?.title}');
      debugPrint('[FCM]   Body: ${notification?.body}');
      debugPrint('[FCM]   Data: $data');

      // Show notification using local notifications if we have title or body
      if (notification != null &&
          (notification.title != null || notification.body != null)) {
        _showLocalNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
          data: data,
        );
      }

      // Handle custom data from Firebase
      if (data.isNotEmpty) {
        _handleCustomData(data);
      }
    } catch (e) {
      debugPrint('[FCM] Error handling remote message: $e');
    }
  }

  /// Show notification using local notifications plugin
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'firebase_notifications',
            'Firebase Messages',
            channelDescription: 'Notifikasi dari Firebase Cloud Messaging',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null
            ? Uri(queryParameters: data.cast<String, String>()).query
            : null,
      );
    } catch (e) {
      debugPrint('[FCM] Error showing local notification: $e');
    }
  }

  /// Handle custom data from Firebase messages
  void _handleCustomData(Map<String, dynamic> data) {
    // TODO: Implement custom handling based on your app's needs
    // Example: Navigate to specific screen, update UI, trigger actions, etc.
    debugPrint('[FCM] Processing custom data: $data');
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Error getting FCM token: $e');
      return null;
    }
  }

  /// Get FCM token (alias for compatibility)
  Future<String?> getFcmToken() => getFCMToken();

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error unsubscribing from topic: $e');
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

  /// Android 13+: Request exact alarms permission if supported
  Future<bool> requestExactAlarmsPermission() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;
      final result = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('[NotificationService] Request exact alarms result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[NotificationService] Error requesting exact alarms: $e');
      return false;
    }
  }

  /// Schedule notification for a specific task
  ///
  /// **DEPRECATED**: Use Firebase Cloud Messaging via ReminderService instead.
  /// This local-only scheduling does not work when app is closed or device restarts.
  /// Use ReminderService.scheduleFirebaseReminder() for reliable backend-driven notifications.
  ///
  /// [taskId] - Unique identifier for the task
  /// [taskTitle] - Title of the task
  /// [taskDescription] - Description of the task
  /// [scheduledDateTime] - When the task is scheduled
  /// [reminderMinutesBefore] - How many minutes before to remind (e.g., 15)
  @Deprecated(
    'Use ReminderService.scheduleFirebaseReminder() for backend-driven notifications',
  )
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

        // Try scheduling with exact alarm first; fall back to inexact if not permitted
        Future<void> _schedule(AndroidScheduleMode mode) async {
          await _localNotifications.zonedSchedule(
            taskId,
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
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }

        try {
          await _schedule(AndroidScheduleMode.exactAllowWhileIdle);
          debugPrint(
            '[NotificationService] ✓ Scheduled (exact) reminder at ${reminderDateTime.toString()}',
          );
        } on PlatformException catch (e) {
          if (e.code == 'exact_alarms_not_permitted') {
            debugPrint(
              '[NotificationService] Exact alarms not permitted; requesting permission and falling back to inexact.',
            );
            await requestExactAlarmsPermission();
            // Fall back to inexact so reminder still works
            await _schedule(AndroidScheduleMode.inexact);
            debugPrint(
              '[NotificationService] ✓ Scheduled (inexact) reminder at ${reminderDateTime.toString()}',
            );
          } else {
            debugPrint('Error scheduling notification (exact): $e');
            rethrow;
          }
        }
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
  ///
  /// **DEPRECATED**: For Firebase backend notifications, use backend API to cancel reminders.
  /// This only cancels local notifications.
  @Deprecated('Use backend API to cancel Firebase reminders')
  Future<void> cancelTaskReminder(int taskId) async {
    try {
      await _localNotifications.cancel(taskId);
      debugPrint('Cancelled reminder for task $taskId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  ///
  /// **DEPRECATED**: For Firebase backend notifications, use backend API to cancel all reminders.
  /// This only cancels local notifications.
  @Deprecated('Use backend API to cancel all Firebase reminders')
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
