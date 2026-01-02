import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../data/services/supabase_service.dart';

/// Helper untuk load streak data dari database
class StreakDatabase {
  static final _supabaseService = Get.find<SupabaseService>();

  /// Load current streak dari database untuk user tertentu
  static Future<int> loadCurrentStreak(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('user_streaks')
          .select('current_streak')
          .eq('user_id', userId)
          .single()
          .timeout(const Duration(seconds: 5));

      return (response['current_streak'] as int?) ?? 0;
    } catch (e) {
      debugPrint('[StreakDatabase] Error loading current streak: $e');
      return 0;
    }
  }

  /// Load longest streak dari database
  static Future<int> loadLongestStreak(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('user_streaks')
          .select('longest_streak')
          .eq('user_id', userId)
          .single()
          .timeout(const Duration(seconds: 5));

      return (response['longest_streak'] as int?) ?? 0;
    } catch (e) {
      debugPrint('[StreakDatabase] Error loading longest streak: $e');
      return 0;
    }
  }

  /// Load progress untuk tanggal tertentu
  static Future<double> loadProgressForDate(
    String userId,
    String dateIso,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('daily_progress')
          .select('progress_percentage')
          .eq('user_id', userId)
          .eq('date', dateIso)
          .single()
          .timeout(const Duration(seconds: 5));

      return (response['progress_percentage'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('[StreakDatabase] Error loading progress: $e');
      return 0.0;
    }
  }

  /// Load progress history (last N days)
  static Future<List<Map<String, dynamic>>> loadProgressHistory(
    String userId, {
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final startDateIso =
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      final response = await _supabaseService.client
          .from('daily_progress')
          .select()
          .eq('user_id', userId)
          .gte('date', startDateIso)
          .order('date', ascending: false)
          .timeout(const Duration(seconds: 5));

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[StreakDatabase] Error loading progress history: $e');
      return [];
    }
  }

  /// Update longest streak jika current streak lebih besar
  static Future<void> updateLongestStreak(
    String userId,
    int currentStreak,
  ) async {
    try {
      final longestSoFar = await loadLongestStreak(userId);

      if (currentStreak > longestSoFar) {
        await _supabaseService.client.from('user_streaks').upsert({
          'user_id': userId,
          'longest_streak': currentStreak,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');

        debugPrint('[StreakDatabase] Updated longest streak to $currentStreak');
      }
    } catch (e) {
      debugPrint('[StreakDatabase] Error updating longest streak: $e');
    }
  }

  /// Sync local data ke database (call ini jika ada lag)
  static Future<void> forceSync(
    String userId,
    int currentStreak,
    String lastCompletedDate,
    double todayProgress,
  ) async {
    try {
      final today = DateTime.now();
      final todayIso =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Upsert streak
      await _supabaseService.client.from('user_streaks').upsert({
        'user_id': userId,
        'current_streak': currentStreak,
        'last_completed_date': lastCompletedDate,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Upsert progress
      await _supabaseService.client.from('daily_progress').upsert({
        'user_id': userId,
        'date': todayIso,
        'progress_percentage': todayProgress,
        'is_completed': todayProgress >= 100.0,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      debugPrint('[StreakDatabase] Force sync completed');
    } catch (e) {
      debugPrint('[StreakDatabase] Error force syncing: $e');
    }
  }

  /// Get stats untuk leaderboard atau profile
  static Future<Map<String, dynamic>> getUserStreakStats(String userId) async {
    try {
      final streak = await _supabaseService.client
          .from('user_streaks')
          .select()
          .eq('user_id', userId)
          .single()
          .timeout(const Duration(seconds: 5));

      return streak as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[StreakDatabase] Error loading stats: $e');
      return {};
    }
  }
}
