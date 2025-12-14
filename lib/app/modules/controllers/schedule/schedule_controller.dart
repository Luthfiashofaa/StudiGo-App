import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException;

import '../../../data/services/auth_persistence_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../bindings/auth/login_binding.dart';
import '../../views/auth/login_view.dart';

class ScheduleController extends GetxController {
  ScheduleController({SupabaseService? supabase})
    : _supabase = supabase ?? Get.find<SupabaseService>();

  final SupabaseService _supabase;

  final RxBool isLoading = false.obs;
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

      if (date != null) {
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));
        schedules.assignAll(
          list.where((item) {
            final raw = item['start_time']?.toString();
            // Parse as local time to avoid UTC shift
            DateTime? dt;
            if (raw != null) {
              // If stored as "YYYY-MM-DD HH:MM:SS", parse directly without UTC conversion
              try {
                dt = DateTime.parse(raw.replaceAll(' ', 'T'));
              } catch (_) {
                dt = DateTime.tryParse(raw);
              }
            }
            if (dt == null) return false;
            // Compare only date parts to avoid timezone issues
            final itemDate = DateTime(dt.year, dt.month, dt.day);
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

    await _supabase
        .from('schedules')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
    schedules.removeWhere((item) => item['id'] == id);
  }
}
