import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/notification_service.dart';
import '../../../data/services/supabase_service.dart';
import '../home/home_controller.dart';
import 'schedule_controller.dart';

class AddScheduleController extends GetxController {
  AddScheduleController({SupabaseService? supabase})
    : _supabase = supabase ?? Get.find<SupabaseService>();

  final SupabaseService _supabase;
  final NotificationService _notificationService = NotificationService();

  final RxBool isSaving = false.obs;

  DateTime? _parseToLocal(dynamic raw) {
    if (raw is DateTime) return raw.toLocal();
    if (raw is String) {
      try {
        // Parse as UTC (ISO 8601 format from database)
        final utc = DateTime.parse(raw).toUtc();
        final local = utc.toLocal();
        debugPrint(
          '[AddScheduleController] _parseToLocal: $raw -> $local (UTC+local)',
        );
        return local;
      } catch (e) {
        debugPrint('[AddScheduleController] _parseToLocal FAILED: $raw - $e');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeScheduleMap(Map<String, dynamic> schedule) {
    final normalized = Map<String, dynamic>.from(schedule);

    final startLocal = _parseToLocal(schedule['start_time']);
    final endLocal = _parseToLocal(schedule['end_time']);
    final dateLocal = _parseToLocal(schedule['date']);

    debugPrint('[AddScheduleController] Normalizing schedule:');
    debugPrint(
      '[AddScheduleController]   Raw start_time: ${schedule['start_time']}',
    );
    debugPrint('[AddScheduleController]   Parsed start_time: $startLocal');

    if (startLocal != null) {
      normalized['start_time'] = startLocal.toIso8601String();
      debugPrint(
        '[AddScheduleController]   Normalized start_time: ${normalized['start_time']}',
      );
    }
    if (endLocal != null) {
      normalized['end_time'] = endLocal.toIso8601String();
    }
    if (dateLocal != null) {
      normalized['date'] = DateTime(
        dateLocal.year,
        dateLocal.month,
        dateLocal.day,
      ).toIso8601String();
    }

    return normalized;
  }

  void _upsertLocalSchedule(Map<String, dynamic> schedule) {
    if (!Get.isRegistered<ScheduleController>()) return;
    final scheduleCtrl = Get.find<ScheduleController>();
    final normalized = _normalizeScheduleMap(schedule);
    final idx = scheduleCtrl.schedules.indexWhere(
      (e) => e['id'] == normalized['id'],
    );
    if (idx >= 0) {
      debugPrint('Updating existing schedule at index $idx');
      scheduleCtrl.schedules[idx] = normalized;
    } else {
      debugPrint('Adding new schedule to local cache');
      scheduleCtrl.schedules.add(normalized);
    }

    // Update full list (calendar dots, future fetch reuse)
    final idxAll = scheduleCtrl.allSchedules.indexWhere(
      (e) => e['id'] == normalized['id'],
    );
    if (idxAll >= 0) {
      scheduleCtrl.allSchedules[idxAll] = normalized;
    } else {
      scheduleCtrl.allSchedules.add(normalized);
    }

    int _cmp(Map<String, dynamic> a, Map<String, dynamic> b) {
      final sa = a['start_time']?.toString();
      final sb = b['start_time']?.toString();
      return (sa ?? '').compareTo(sb ?? '');
    }

    scheduleCtrl.schedules.sort(_cmp);
    scheduleCtrl.allSchedules.sort(_cmp);
    scheduleCtrl.schedules.refresh();
    scheduleCtrl.allSchedules.refresh();
    debugPrint('Total schedules in cache: ${scheduleCtrl.schedules.length}');

    // Trigger home update - ensure it's always called
    _triggerHomeUpdate();
  }

  void _triggerHomeUpdate() {
    try {
      debugPrint('[AddScheduleController] Triggering home update...');
      if (!Get.isRegistered<HomeController>()) {
        debugPrint(
          '[AddScheduleController] HomeController not registered, putting it now',
        );
        Get.put(HomeController(), permanent: false);
      }
      final homeCtrl = Get.find<HomeController>();
      debugPrint(
        '[AddScheduleController] Found HomeController, calling updateTodayTasksFromSchedule',
      );
      homeCtrl.updateTodayTasksFromSchedule();
      debugPrint(
        '[AddScheduleController] updateTodayTasksFromSchedule completed',
      );
    } catch (e) {
      debugPrint('[AddScheduleController] Error triggering home update: $e');
    }
  }

  Future<void> createSchedule({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool repeatDaily,
    required String priority,
    String? category,
  }) async {
    if (isSaving.value) return;

    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('User belum login.');
    }

    // Combine the selected date with start/end time. Use local DateTime to avoid UTC shift.
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Store as local ISO 8601 to keep exact picked time
    // Avoid converting to UTC so the value remains identical
    String formatLocal(DateTime dt) {
      return dt.toIso8601String();
    }

    debugPrint('[AddScheduleController] Creating schedule:');
    debugPrint('[AddScheduleController]   Local startDateTime: $startDateTime');
    debugPrint(
      '[AddScheduleController]   Local ISO start_time: ${formatLocal(startDateTime)}',
    );

    final payload = {
      'user_id': user.id,
      'title': title,
      'description': description,
      'date': formatLocal(DateTime(date.year, date.month, date.day)),
      'start_time': formatLocal(startDateTime),
      'end_time': formatLocal(endDateTime),
      'repeat_daily': repeatDaily,
      'priority': priority,
      'category': category,
    };

    isSaving.value = true;
    try {
      final inserted = await _supabase
          .from('schedules')
          .insert(payload)
          .select()
          .maybeSingle();

      if (inserted is Map<String, dynamic>) {
        _upsertLocalSchedule(inserted);

        // Schedule notification reminder if enabled
        await _scheduleNotificationIfEnabled(inserted, startDateTime);
      } else {
        // fallback: refetch when no data returned
        if (Get.isRegistered<ScheduleController>()) {
          await Get.find<ScheduleController>().fetchSchedules();
        }
      }

      _triggerHomeUpdate();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateSchedule({
    required String id,
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool repeatDaily,
    required String priority,
    String? category,
  }) async {
    if (isSaving.value) return;

    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('User belum login.');
    }

    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Store as local ISO 8601 to keep exact picked time
    String formatLocal(DateTime dt) {
      return dt.toIso8601String();
    }

    debugPrint('[AddScheduleController] Updating schedule:');
    debugPrint('[AddScheduleController]   Local startDateTime: $startDateTime');
    debugPrint(
      '[AddScheduleController]   Local ISO start_time: ${formatLocal(startDateTime)}',
    );

    final payload = {
      'title': title,
      'description': description,
      'date': formatLocal(DateTime(date.year, date.month, date.day)),
      'start_time': formatLocal(startDateTime),
      'end_time': formatLocal(endDateTime),
      'repeat_daily': repeatDaily,
      'priority': priority,
      'category': category,
      'updated_at': formatLocal(DateTime.now()),
    };

    isSaving.value = true;
    try {
      final updated = await _supabase
          .from('schedules')
          .update(payload)
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .maybeSingle();

      if (updated is Map<String, dynamic>) {
        _upsertLocalSchedule(updated);

        // Reschedule notification reminder if enabled
        await _scheduleNotificationIfEnabled(updated, startDateTime);
      } else {
        if (Get.isRegistered<ScheduleController>()) {
          await Get.find<ScheduleController>().fetchSchedules();
        }
      }

      _triggerHomeUpdate();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } finally {
      isSaving.value = false;
    }
  }

  /// Schedule notification reminder based on user's notification settings
  Future<void> _scheduleNotificationIfEnabled(
    Map<String, dynamic> schedule,
    DateTime startDateTime,
  ) async {
    try {
      // Get user's notification settings from ProfileController or fetch from database
      final user = _supabase.currentUser;
      if (user == null) return;

      // Fetch user's notification preferences
      final userPrefs = await _supabase
          .from('users')
          .select('enable_notifications, reminder_minutes_before')
          .eq('id', user.id)
          .maybeSingle();

      if (userPrefs == null) return;

      final enableNotifications =
          userPrefs['enable_notifications'] as bool? ?? true;
      final reminderMinutesBefore =
          userPrefs['reminder_minutes_before'] as int? ?? 15;

      if (!enableNotifications) {
        debugPrint(
          '[AddScheduleController] Notifications disabled, skipping schedule',
        );
        return;
      }

      // Extract task ID and details
      final taskId = schedule['id']?.toString() ?? '';
      final title = schedule['title']?.toString() ?? 'Task';
      final description = schedule['description']?.toString() ?? '';

      // Use hash of ID to get a numeric ID for notification
      final numericId = taskId.hashCode.abs() % 2147483647; // Max 32-bit int

      await _notificationService.scheduleTaskReminder(
        taskId: numericId,
        taskTitle: title,
        taskDescription: description,
        scheduledDateTime: startDateTime,
        reminderMinutesBefore: reminderMinutesBefore,
      );

      debugPrint(
        '[AddScheduleController] Notification scheduled for task: $title',
      );
    } catch (e) {
      debugPrint('[AddScheduleController] Error scheduling notification: $e');
      // Don't throw - notification failure shouldn't block schedule creation
    }
  }
}
