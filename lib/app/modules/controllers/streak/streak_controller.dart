import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/supabase_service.dart';
import 'mission_models.dart';

class StreakController extends GetxController {
  final RxInt streakCount = 0.obs;
  final RxList<DayHistory> history = <DayHistory>[].obs;
  final RxString lastCompletedIso = ''.obs;

  // Daily progress tracking (0-100)
  final RxDouble todayProgress = 0.0.obs;
  final RxString todayProgressDate = ''.obs;

  // Map dari date (YYYY-MM-DD) → is_completed untuk tampilkan indikator
  final RxMap<String, bool> dayCompletionStatus = <String, bool>{}.obs;

  // Tanggal Day 1 (hari pertama akun dibuat / data pertama di database)
  final Rx<DateTime?> firstDayDate = Rx<DateTime?>(null);

  // decorative houses support (kept for existing painter logic)
  final RxList<String> houses = <String>[].obs;
  final RxInt selectedHouseIndex = (-1).obs;

  bool hasAutoScrolled = false;
  late final ScrollController scrollController;

  SharedPreferences? _prefs;
  bool _hydrated = false;

  // Supabase service
  final _supabaseService = Get.find<SupabaseService>();
  String? _currentUserId;

  // Track actual completed tasks for database
  int _todayCompletedTasks = 0;

  static const _kStreakCount = 'streak_count';
  static const _kHistory = 'streak_history';
  static const _kLastCompleted = 'streak_last_completed';
  static const _kTodayProgress = 'today_progress';
  static const _kTodayProgressDate = 'today_progress_date';

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(() {
      final pos = scrollController.position;
      if (!pos.hasPixels) return;
      if (pos.pixels > pos.maxScrollExtent - 300) {
        loadMore();
      }
    });

    // Initialize with default values for new login
    _initializeForNewLogin();
  }

  /// Initialize streak data for new login
  /// Set default values but DON'T set todayProgressDate yet
  /// Let reconcileForToday() handle the first check
  Future<void> _initializeForNewLogin() async {
    _prefs ??= await SharedPreferences.getInstance();
    _currentUserId = _supabaseService.currentUser?.id;

    // Always start with streak = 0 on login
    // reconcileForToday() will determine correct streak based on yesterday's database data
    streakCount.value = 0;
    lastCompletedIso.value = '';
    history.clear();

    todayProgress.value = 0.0;
    _todayCompletedTasks = 0;

    // DON'T set todayProgressDate here - let reconcileForToday() handle it
    // This way, first call to reconcileForToday() will always detect a "new day"
    // and properly check yesterday's progress from database

    _hydrated = true;

    debugPrint(
      '[StreakController] Initialized for new login with streak=0, todayProgressDate will be set by reconcileForToday()',
    );
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Calculate actual streak from database by counting consecutive days with 100% completion
  /// Streak = jumlah hari berturut-turut DARI KEMARIN KE BELAKANG dengan progres 100%
  /// Hari ini (today) TIDAK dihitung dalam streak karena masih berjalan
  Future<int> calculateStreakFromDatabase() async {
    if (_currentUserId == null) return 0;

    try {
      final result = await _supabaseService.client
          .from('daily_progress')
          .select('date, is_completed')
          .eq('user_id', _currentUserId!)
          .eq('is_completed', true)
          .order('date', ascending: false)
          .limit(100); // Get up to 100 completed days

      if (result.isEmpty) return 0;

      // Parse all completed dates
      final completedDates = (result as List)
          .map((item) => DateTime.parse(item['date'] as String))
          .toList();

      // Normalize dates to remove time component
      final completedDateSet = completedDates
          .map((date) => DateTime(date.year, date.month, date.day))
          .toSet();

      if (completedDateSet.isEmpty) return 0;

      // Start counting from YESTERDAY (not today) going backwards
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final yesterday = todayOnly.subtract(const Duration(days: 1));

      int streak = 0;
      DateTime checkDate = yesterday;

      // Count consecutive completed days starting from yesterday
      while (completedDateSet.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));

        // Safety break after checking reasonable history
        if (streak > 365) break;
      }

      debugPrint(
        '[StreakController] Calculated streak from database: $streak (counting from yesterday backwards)',
      );
      return streak;
    } catch (e) {
      debugPrint(
        '[StreakController] Error calculating streak from database: $e',
      );
      return 0;
    }
  }

  /// Fetch completion status untuk semua hari dari database
  /// Juga include hari kemarin jika progress >= 100% untuk handling edge case
  Future<void> fetchDayCompletionStatus() async {
    if (_currentUserId == null) return;

    try {
      // First, get the account creation date from users table
      DateTime? accountCreatedAt;
      try {
        final userResult = await _supabaseService.client
            .from('users')
            .select('created_at')
            .eq('id', _currentUserId!)
            .single();

        if (userResult['created_at'] != null) {
          accountCreatedAt = DateTime.parse(userResult['created_at'] as String);
          // Normalize to remove time component
          accountCreatedAt = DateTime(
            accountCreatedAt.year,
            accountCreatedAt.month,
            accountCreatedAt.day,
          );
          debugPrint(
            '[StreakController] Account created at: $accountCreatedAt',
          );
        }
      } catch (e) {
        debugPrint('[StreakController] Could not fetch user created_at: $e');
      }

      // Then get all daily progress records
      final result = await _supabaseService.client
          .from('daily_progress')
          .select('date, is_completed')
          .eq('user_id', _currentUserId!)
          .order('date', ascending: false);

      final Map<String, bool> status = {};
      DateTime? earliestProgress;

      debugPrint(
        '[StreakController] Fetched ${result.length} daily_progress records from database',
      );

      for (final item in result) {
        final date = item['date'] as String?;
        final isCompleted = item['is_completed'] as bool? ?? false;
        if (date != null) {
          status[date] = isCompleted;

          // Track earliest date in daily_progress
          final dateTime = DateTime.parse(date);
          if (earliestProgress == null || dateTime.isBefore(earliestProgress)) {
            earliestProgress = dateTime;
          }

          // Log first 5 and last 5 entries for debugging
          if (status.length <= 5 || result.indexOf(item) >= result.length - 5) {
            debugPrint(
              '[StreakController] Day data: $date → ${isCompleted ? "✅ Completed" : "❌ Incomplete"}',
            );
          }
        }
      }

      // 🔥 IMPORTANT: If yesterday's progress >= 100%, mark it as completed
      // This handles edge case where user completes missions and data
      // might not have synced yet before viewing next day
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayIso =
          '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // If yesterday's progress is >= 100%, ensure it's marked as completed
      // (even if database sync was delayed)
      if (status.containsKey(yesterdayIso) &&
          status[yesterdayIso] == false &&
          todayProgressDate.value == _getTodayIso()) {
        // Yesterday exists in DB but marked incomplete - don't override
        // The database is source of truth for past days
      } else if (!status.containsKey(yesterdayIso) &&
          lastCompletedIso.value == yesterdayIso) {
        // Yesterday was marked complete locally but not in DB - sync it now
        status[yesterdayIso] = true;
        debugPrint(
          '[StreakController] Found local completed yesterday ($yesterdayIso) not in DB, including it',
        );
      }

      dayCompletionStatus.assignAll(status);

      // Use account creation date as Day 1, fallback to earliest progress if not available
      firstDayDate.value = accountCreatedAt ?? earliestProgress;

      debugPrint(
        '[StreakController] Loaded ${status.length} days completion status',
      );
      debugPrint(
        '[StreakController] First day (Day 1) date: ${firstDayDate.value?.toString() ?? "not found"}',
      );
    } catch (e) {
      debugPrint('[StreakController] Error fetching day completion status: $e');
    }
  }

  /// Ensure persisted data is loaded once.
  /// Note: Called after _initializeForNewLogin() to preserve today's date
  Future<void> restoreFromStorage() async {
    if (_hydrated) return;
    _prefs ??= await SharedPreferences.getInstance();
    _currentUserId = _supabaseService.currentUser?.id;

    streakCount.value = _prefs?.getInt(_kStreakCount) ?? 0;
    lastCompletedIso.value = _prefs?.getString(_kLastCompleted) ?? '';

    // Only restore progress if it's from today
    final savedTodayProgressDate = _prefs?.getString(_kTodayProgressDate) ?? '';
    if (savedTodayProgressDate.isNotEmpty &&
        savedTodayProgressDate == todayProgressDate.value) {
      todayProgress.value = _prefs?.getDouble(_kTodayProgress) ?? 0.0;
    }

    final rawHistory = _prefs?.getString(_kHistory);
    if (rawHistory != null) {
      final decoded = (jsonDecode(rawHistory) as List<dynamic>)
          .map((e) => DayHistory.fromJson(e as Map<String, dynamic>))
          .toList();
      history.assignAll(decoded);
    }

    _hydrated = true;

    // Sync to database after loading local data
    if (_currentUserId != null) {
      await _syncToDatabase();
    }
  }

  /// Reconcile streak when day changes.
  /// Logic:
  /// 1. If today is a new day (different from tracking date)
  /// 2. Calculate streak from database (consecutive 100% days from yesterday backwards)
  /// 3. Reset today's progress to 0%
  Future<void> reconcileForToday(String todayIso) async {
    await restoreFromStorage();

    debugPrint(
      '[StreakController] reconcileForToday called with todayIso=$todayIso, current todayProgressDate=${todayProgressDate.value}, currentStreak=${streakCount.value}',
    );

    // Check if it's a new day
    if (todayProgressDate.value == todayIso) {
      debugPrint(
        '[StreakController] Same day detected, skipping reconciliation',
      );
      return; // Still the same day, no reconciliation needed
    }

    // Fetch all day completion status from database for UI display
    await fetchDayCompletionStatus();

    debugPrint(
      '[StreakController] New day detected: $todayIso (was ${todayProgressDate.value})',
    );

    // Calculate actual streak from all historical data
    // Streak counts consecutive 100% days from YESTERDAY backwards
    final calculatedStreak = await calculateStreakFromDatabase();
    streakCount.value = calculatedStreak;

    debugPrint(
      '[StreakController] Recalculated streak from database: $calculatedStreak',
    );

    // Reset today's progress to 0%
    todayProgress.value = 0.0;
    todayProgressDate.value = todayIso;
    _todayCompletedTasks = 0;

    await _persist();
    debugPrint(
      '[StreakController] Reconciliation complete. Streak=${streakCount.value}, todayProgressDate=$todayProgressDate, lastCompleted=${lastCompletedIso.value}',
    );
  }

  /// Update today's progress (0-100). Streak will be recalculated next day by reconcileForToday().
  Future<void> updateTodayProgress(
    double progress, {
    int? completedTaskCount,
  }) async {
    await restoreFromStorage();
    final today = _getTodayIso();

    // Ensure we're tracking today
    if (todayProgressDate.value != today) {
      todayProgressDate.value = today;
      todayProgress.value = 0.0;
    }

    // Clamp progress between 0-100
    final newProgress = progress.clamp(0.0, 100.0);
    todayProgress.value = newProgress;

    // Store completed task count for database sync
    _todayCompletedTasks = completedTaskCount ?? 0;

    await _persist();

    // Note: Streak increment happens the next day in reconcileForToday()
    // when it recalculates from database
  }

  /// Update longest streak di database jika current streak lebih besar
  Future<void> _updateLongestStreakIfNeeded() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      // Query longest streak dari database
      final result = await _supabaseService.client
          .from('user_streaks')
          .select('longest_streak')
          .eq('user_id', userId)
          .maybeSingle();

      final longestSoFar = (result?['longest_streak'] as int?) ?? 0;

      // Update jika current streak lebih besar
      if (streakCount.value > longestSoFar) {
        await _supabaseService.client.from('user_streaks').upsert({
          'user_id': userId,
          'longest_streak': streakCount.value,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');

        debugPrint(
          '[StreakController] Updated longest streak to ${streakCount.value}',
        );
      }
    } catch (e) {
      debugPrint('[StreakController] Error updating longest streak: $e');
    }
  }

  String _getTodayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Mark today's missions as completed and advance the streak/history.
  /// Returns true if streak was successfully incremented, false if already completed today.
  Future<bool> markDayCompleted({
    required String dateIso,
    required List<Mission> missions,
  }) async {
    await restoreFromStorage();
    if (lastCompletedIso.value == dateIso) return false; // already counted

    final today = DateTime.parse(dateIso);
    int nextCount = 1;

    if (lastCompletedIso.value.isNotEmpty) {
      final last = DateTime.parse(lastCompletedIso.value);
      final diff = today.difference(last).inDays;
      nextCount = (diff == 1) ? streakCount.value + 1 : 1;
    }

    streakCount.value = nextCount;
    lastCompletedIso.value = dateIso;
    history.add(
      DayHistory(
        dayNumber: nextCount,
        dateIso: dateIso,
        completedMissions: missions.map((m) => m.title).toList(),
      ),
    );

    await _persist();
    return true; // Successfully incremented streak
  }

  void loadMore({int add = 20}) {}

  // ----- Houses management (kept for painter decorations) -----
  void addHouse(String name) => houses.add(name);

  void removeHouseAt(int index) {
    if (index >= 0 && index < houses.length) houses.removeAt(index);
  }

  void selectHouse(int index) {
    if (index >= 0 && index < houses.length) {
      selectedHouseIndex.value = index;
    } else {
      selectedHouseIndex.value = -1;
    }
  }

  void loadMoreHouses({int add = 5}) {
    final start = houses.length + 1;
    for (var i = 0; i < add; i++) {
      houses.add('Rumah ${start + i}');
    }
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_kStreakCount, streakCount.value);
    await _prefs?.setString(_kLastCompleted, lastCompletedIso.value);
    await _prefs?.setDouble(_kTodayProgress, todayProgress.value);
    await _prefs?.setString(_kTodayProgressDate, todayProgressDate.value);
    await _prefs?.setString(
      _kHistory,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );

    // Sync to database
    if (_currentUserId != null) {
      await _syncToDatabase();
    }
  }

  /// Public method to force sync to database immediately
  /// Used when critical data (like daily completion) needs guaranteed persistence
  Future<void> syncToDatabaseNow() async {
    await restoreFromStorage();
    await _syncToDatabase();
  }

  /// Sync streak data to Supabase database
  Future<void> _syncToDatabase() async {
    try {
      if (_currentUserId == null) return;

      final today = DateTime.now();
      final todayIso =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      debugPrint(
        '[StreakController] Syncing to database for user: $_currentUserId',
      );

      // Prepare userId as local variable to avoid nullable issues
      final userId = _currentUserId!;

      // Upsert user streak data
      await _supabaseService.client.from('user_streaks').upsert({
        'user_id': userId,
        'current_streak': streakCount.value,
        'last_completed_date': lastCompletedIso.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Insert daily progress record with actual completed tasks count
      final isCompleted = todayProgress.value >= 100.0;

      await _supabaseService.client.from('daily_progress').upsert({
        'user_id': userId,
        'date': todayIso,
        'progress_percentage': todayProgress.value,
        'completed_tasks': _todayCompletedTasks,
        'is_completed': isCompleted,
      }, onConflict: 'user_id,date');

      debugPrint(
        '[StreakController] ✅ Successfully synced to database: '
        'date=$todayIso, ${_todayCompletedTasks} tasks, ${todayProgress.value.toStringAsFixed(1)}% complete, isCompleted=$isCompleted',
      );

      // Update longest streak if needed
      await _updateLongestStreakIfNeeded();
    } catch (e) {
      debugPrint('[StreakController] Error syncing to database: $e');
      // Silently fail - data is still saved locally
    }
  }
}
