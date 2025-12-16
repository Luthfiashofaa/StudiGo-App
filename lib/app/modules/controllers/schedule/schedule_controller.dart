import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException;

import '../../../data/services/auth_persistence_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../bindings/auth/login_binding.dart';
import '../../views/auth/login_view.dart';
import '../home/home_controller.dart';

class ScheduleController extends GetxController {
  ScheduleController({SupabaseService? supabase})
    : _supabase = supabase ?? Get.find<SupabaseService>();

  final SupabaseService _supabase;
  final NotificationService _notificationService = NotificationService();

  final RxBool isLoading = false.obs;
  // Full list of schedules for indicator dots
  final RxList<Map<String, dynamic>> allSchedules =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> schedules = <Map<String, dynamic>>[].obs;

  Future<void> _handleExpiredSession(String reason) async {
    if (Get.isRegistered<AuthPersistenceService>()) {
      await Get.find<AuthPersistenceService>().clearLoginState();
    }
    await _supabase.client.auth.signOut();
    Get.offAll(() => const LoginView(), binding: LoginBinding());
    throw Exception(reason);
  }

  Future<void> fetchSchedules({DateTime? date}) async {
    final user = _supabase.currentUser;
    if (user == null) {
      await _handleExpiredSession('User belum login.');
      return;
    }

    isLoading.value = true;
    try {
      final data = await _supabase
          .from('schedules')
          .select()
          .eq('user_id', user.id)
          .order('start_time', ascending: true)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Request timeout, cek koneksi internet'),
          );

      final list = List<Map<String, dynamic>>.from(data);
      allSchedules.assignAll(list);

      if (date != null) {
        schedules.assignAll(
          list.where((item) {
            final bool repeats = item['repeat_daily'] == true;
            // Prefer explicit date column to avoid timezone shifts
            final rawDate = item['date']?.toString();
            final rawStart = item['start_time']?.toString();

            DateTime? dateValue;
            if (rawDate != null) {
              try {
                dateValue = DateTime.parse(rawDate.replaceAll(' ', 'T')).toLocal();
              } catch (_) {
                dateValue = DateTime.tryParse(rawDate)?.toLocal();
              }
            }
            // Fallback to start_time if date column missing
            if (dateValue == null && rawStart != null) {
              try {
                dateValue = DateTime.parse(rawStart.replaceAll(' ', 'T')).toLocal();
              } catch (_) {
                dateValue = DateTime.tryParse(rawStart)?.toLocal();
              }
            }

            if (dateValue == null) return false;
            final itemDate = DateTime(dateValue.year, dateValue.month, dateValue.day);

            if (repeats) {
              // Repeat only from its start date forward (inclusive)
              return !date.isBefore(itemDate);
            }

            return itemDate.year == date.year &&
                itemDate.month == date.month &&
                itemDate.day == date.day;
          }),
        );
      } else {
        schedules.assignAll(list);
      }
    } on PostgrestException catch (e) {
      Get.snackbar('Error DB', e.message);
    } on AuthRetryableFetchException catch (e) {
      await _handleExpiredSession(
        'Sesi auth kedaluwarsa, silakan login lagi. (${e.message})',
      );
    } catch (e) {
      // Handle network errors (connection reset, timeout, etc)
      final msg = e.toString();
      if (msg.contains('Connection') || msg.contains('timeout')) {
        Get.snackbar(
          'Koneksi Gagal',
          'Tidak dapat terhubung ke server. Periksa internet Anda.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar('Error', msg);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSchedule(String id) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('User belum login.');

    // Cancel notification reminder for this schedule
    try {
      final taskId = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (taskId > 0) {
        await _notificationService.cancelTaskReminder(taskId);
      }
    } catch (e) {
      debugPrint('Warning: Could not cancel notification: $e');
    }

    await _supabase
        .from('schedules')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
    schedules.removeWhere((item) => item['id'] == id);
    allSchedules.removeWhere((item) => item['id'] == id);
    debugPrint('Schedule $id deleted from local cache');

    // Trigger home update after delete so today's tasks refresh
    if (Get.isRegistered<HomeController>()) {
      try {
        Get.find<HomeController>().updateTodayTasksFromSchedule();
        debugPrint('Home controller updated after schedule delete');
      } catch (e) {
        debugPrint('Warning: Could not update home after delete: $e');
      }
    }
  }
}
