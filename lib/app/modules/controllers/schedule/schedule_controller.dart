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
          .order('start_time', ascending: true);

      final list = List<Map<String, dynamic>>.from(data);

      if (date != null) {
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));
        schedules.assignAll(
          list.where((item) {
            final raw = item['start_time']?.toString();
            final dt = raw != null ? DateTime.tryParse(raw) : null;
            if (dt == null) return false;
            return dt.isAfter(
                  start.subtract(const Duration(milliseconds: 1)),
                ) &&
                dt.isBefore(end);
          }),
        );
      } else {
        schedules.assignAll(list);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } on AuthRetryableFetchException catch (e) {
      await _handleExpiredSession(
        'Sesi auth kedaluwarsa, silakan login lagi. (${e.message})',
      );
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
