import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/supabase_service.dart';

class AddScheduleController extends GetxController {
  AddScheduleController({SupabaseService? supabase})
    : _supabase = supabase ?? Get.find<SupabaseService>();

  final SupabaseService _supabase;

  final RxBool isSaving = false.obs;

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

    // Format as local time string (YYYY-MM-DD HH:MM:SS) to preserve date
    String formatLocal(DateTime dt) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
    }

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
      await _supabase.from('schedules').insert(payload);
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

    // Format as local time string (YYYY-MM-DD HH:MM:SS) to preserve date
    String formatLocal(DateTime dt) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
    }

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
      await _supabase
          .from('schedules')
          .update(payload)
          .eq('id', id)
          .eq('user_id', user.id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } finally {
      isSaving.value = false;
    }
  }
}
