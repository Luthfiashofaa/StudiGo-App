import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();

  factory ReminderService() {
    return _instance;
  }

  ReminderService._internal();

  final _supabase = Supabase.instance.client;

  /// Save reminder to backend for Firebase push notification
  ///
  /// [userId] - Current user ID
  /// [deviceToken] - FCM token from NotificationService
  /// [title] - Notification title
  /// [body] - Notification body
  /// [scheduledDateTime] - When to send notification
  /// [minutesBefore] - Send X minutes before scheduled time (optional)
  /// [category] - Schedule category for notification styling (optional)
  Future<bool> scheduleFirebaseReminder({
    required String userId,
    required String deviceToken,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    int minutesBefore = 5,
    String? category,
  }) async {
    try {
      // Calculate reminder time (minutesBefore sebelum scheduled time)
      final reminderTime = scheduledDateTime.subtract(
        Duration(minutes: minutesBefore),
      );

      // Convert to UTC for backend storage
      final reminderTimeUtc = reminderTime.toUtc();

      debugPrint(
        '[ReminderService] Scheduling Firebase reminder:'
        '\n  Title: $title'
        '\n  Body: $body'
        '\n  Category: $category'
        '\n  Scheduled (local): ${scheduledDateTime.toString()}'
        '\n  Reminder at (local): ${reminderTime.toString()}'
        '\n  Reminder at (UTC): ${reminderTimeUtc.toString()}'
        '\n  Minutes before: $minutesBefore',
      );

      // Panggil Edge Function untuk simpan reminder ke Supabase
      final response = await _supabase.functions.invoke(
        'send-reminder',
        method: HttpMethod.post,
        body: {
          'user_id': userId,
          'device_token': deviceToken,
          'title': title,
          'body': body,
          'category': category ?? 'Umum',
          'reminder_at': reminderTimeUtc.toIso8601String(),
        },
      );

      debugPrint(
        '[ReminderService] Response received, type: ${response.data.runtimeType}',
      );
      debugPrint('[ReminderService] Response status: ${response.status}');

      // Parse response - it might be a String or Map
      Map<String, dynamic>? data;
      try {
        if (response.data == null) {
          debugPrint('[ReminderService] Response data is null');
          return false;
        }

        if (response.data is String) {
          debugPrint('[ReminderService] Parsing String response...');
          data = json.decode(response.data as String) as Map<String, dynamic>?;
        } else if (response.data is Map) {
          debugPrint('[ReminderService] Response is already a Map');
          data = Map<String, dynamic>.from(response.data as Map);
        } else {
          debugPrint(
            '[ReminderService] Unexpected response type: ${response.data.runtimeType}',
          );
          debugPrint('[ReminderService] Raw response: ${response.data}');
          return false;
        }
      } catch (e, stackTrace) {
        debugPrint('[ReminderService] Error parsing response: $e');
        debugPrint('[ReminderService] Stack trace: $stackTrace');
        debugPrint('[ReminderService] Raw response: ${response.data}');
        return false;
      }

      debugPrint('[ReminderService] Parsed data: $data');

      if (data != null && data['ok'] == true) {
        debugPrint('[ReminderService] ✓ Reminder saved successfully');
        return true;
      } else {
        debugPrint('[ReminderService] ✗ Failed to save reminder: $data');
        return false;
      }
    } catch (e) {
      debugPrint('[ReminderService] Error scheduling reminder: $e');
      return false;
    }
  }

  /// Manual dispatch untuk testing (panggil endpoint /dispatch)
  Future<bool> dispatchPendingReminders() async {
    try {
      debugPrint('[ReminderService] Dispatching pending reminders...');

      final response = await _supabase.functions.invoke(
        'send-reminder/dispatch',
        method: HttpMethod.get,
      );

      debugPrint(
        '[ReminderService] Dispatch response type: ${response.data.runtimeType}',
      );
      debugPrint('[ReminderService] Dispatch status: ${response.status}');

      // Parse response - it might be a String or Map
      Map<String, dynamic>? data;
      try {
        if (response.data == null) {
          debugPrint('[ReminderService] Dispatch response data is null');
          return false;
        }

        if (response.data is String) {
          debugPrint('[ReminderService] Parsing String dispatch response...');
          data = json.decode(response.data as String) as Map<String, dynamic>?;
        } else if (response.data is Map) {
          debugPrint('[ReminderService] Dispatch response is already a Map');
          data = Map<String, dynamic>.from(response.data as Map);
        } else {
          debugPrint(
            '[ReminderService] Unexpected dispatch response type: ${response.data.runtimeType}',
          );
          debugPrint(
            '[ReminderService] Raw dispatch response: ${response.data}',
          );
          return false;
        }
      } catch (e, stackTrace) {
        debugPrint('[ReminderService] Error parsing dispatch response: $e');
        debugPrint('[ReminderService] Stack trace: $stackTrace');
        debugPrint('[ReminderService] Raw response: ${response.data}');
        return false;
      }

      debugPrint('[ReminderService] Parsed dispatch data: $data');

      // Success if we got a valid response with 'sent' field and HTTP status 200
      final success =
          response.status == 200 && data != null && data.containsKey('sent');
      debugPrint(
        '[ReminderService] Dispatch result: $success (sent: ${data?['sent']} reminders)',
      );

      return success;
    } catch (e) {
      debugPrint('[ReminderService] Error dispatching reminders: $e');
      return false;
    }
  }
}
