import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../data/services/supabase_service.dart';
import '../schedule/schedule_controller.dart';
import '../streak/streak_helper.dart';
import '../streak/streak_controller.dart';

class HomeController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  late final ScheduleController _scheduleController;
  SharedPreferences? _prefs;

  // Observable untuk menyimpan nama user
  final userName = 'User'.obs;
  final avatarUrl = ''.obs;
  final isLoadingUser = false.obs;

  // Observable untuk tracking tugas hari ini
  final RxList<Map<String, dynamic>> todayTasks = <Map<String, dynamic>>[].obs;
  final completedTasksCount = 0.obs;

  // Computed property untuk progress percentage
  int get progressPercentage {
    if (todayTasks.isEmpty) return 0;
    return ((completedTasksCount.value / todayTasks.length) * 100).round();
  }

  double get progressValue {
    if (todayTasks.isEmpty) return 0.0;
    return completedTasksCount.value / todayTasks.length;
  }

  @override
  void onInit() {
    super.onInit();
    _initScheduleListener();
    _loadUserData();
    _loadTodayTasks();
  }

  void _initScheduleListener() {
    debugPrint('[HomeController] Initializing schedule listener...');
    if (Get.isRegistered<ScheduleController>()) {
      debugPrint('[HomeController] ScheduleController already registered');
      _scheduleController = Get.find<ScheduleController>();
    } else {
      debugPrint('[HomeController] Putting new ScheduleController');
      _scheduleController = Get.put(ScheduleController());
    }
    debugPrint('[HomeController] Setting up ever() listener on schedules...');
    ever(_scheduleController.schedules, (_) {
      debugPrint('[HomeController] Schedules changed! Updating today tasks...');
      updateTodayTasksFromSchedule();
    });
    debugPrint('[HomeController] Schedule listener initialized successfully');
  }

  Future<void> updateTodayTasksFromSchedule() async {
    debugPrint('[HomeController] updateTodayTasksFromSchedule called');
    _prefs ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayYear = now.year;
    final todayMonth = now.month;
    final todayDay = now.day;
    final today = DateTime(todayYear, todayMonth, todayDay);

    debugPrint(
      '[HomeController] Today date: $todayYear-${todayMonth.toString().padLeft(2, '0')}-${todayDay.toString().padLeft(2, '0')}',
    );
    debugPrint(
      '[HomeController] Total schedules in ScheduleController: ${_scheduleController.allSchedules.length}',
    );

    DateTime? parseLocal(dynamic raw) {
      // Timestamps disimpan sebagai lokal ISO (tanpa konversi tz)
      if (raw is DateTime) return raw;
      if (raw is String) {
        try {
          return DateTime.parse(raw);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    // DEBUG: Log all schedules
    for (int i = 0; i < _scheduleController.allSchedules.length; i++) {
      final item = _scheduleController.allSchedules[i];
      debugPrint(
        '[HomeController] Schedule[$i]: title=${item['title']}, start_time_raw=${item['start_time']}, repeat_daily=${item['repeat_daily']}',
      );
      final dt = parseLocal(item['start_time']);
      if (dt != null) {
        debugPrint(
          '[HomeController]   -> Parsed LOCAL: ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute}',
        );
      } else {
        debugPrint('[HomeController]   -> Parse FAILED');
      }
    }

    final todaySchedules = _scheduleController.allSchedules.where((item) {
      final dt = parseLocal(item['start_time']);
      if (dt == null) {
        return false;
      }

      // Check if it's a recurring task
      final isRepeating = item['repeat_daily'] == true;
      final scheduleDate = DateTime(dt.year, dt.month, dt.day);

      if (isRepeating) {
        // Show repeating tasks if today is on or after the start date
        return !today.isBefore(scheduleDate);
      }

      // For non-repeating tasks, show only if date matches exactly
      return scheduleDate == today;
    }).toList();

    debugPrint(
      '[HomeController] updateTodayTasksFromSchedule: Found ${todaySchedules.length} tasks for today',
    );
    if (todaySchedules.isNotEmpty) {
      debugPrint(
        '[HomeController] First task: ${todaySchedules.first['title']} - start_time: ${todaySchedules.first['start_time']}',
      );
    }

    todayTasks.assignAll(todaySchedules);

    // Restore completion after list refreshed (e.g., when schedules change)
    _restoreTodayCompletion();

    completedTasksCount.value = todayTasks
        .where((task) => task['isCompleted'] == true)
        .length;

    // Update daily progress when schedules change
    _updateDailyProgress();

    debugPrint(
      '[HomeController] todayTasks updated, count: ${todayTasks.length}',
    );
  }

  @override
  void onReady() {
    super.onReady();
    // Delay reactive updates to next frame to avoid "setState during build" error
    Future.delayed(Duration.zero, () {
      _loadUserData();
      _loadTodayTasks();
    });
  }

  // Mengambil data user dari Supabase
  Future<void> _loadUserData() async {
    try {
      isLoadingUser.value = true;

      final user = _supabaseService.currentUser;
      if (user != null) {
        // Ambil data user dari tabel users
        final response = await _supabaseService.client
            .from('users')
            .select('firstname, lastname, name, photo_url')
            .eq('id', user.id)
            .maybeSingle();

        // Handle case where user doesn't exist in public.users yet
        if (response == null) {
          debugPrint(
            '[HomeController] User not found in public.users table, using auth data',
          );
          userName.value = user.email?.split('@').first ?? 'User';
          avatarUrl.value = '';
          return;
        }

        // Gunakan firstname dan lastname jika ada, jika tidak gunakan name atau email
        if (response['firstname'] != null && response['lastname'] != null) {
          userName.value = '${response['firstname']} ${response['lastname']}';
        } else if (response['name'] != null) {
          userName.value = response['name'];
        } else {
          userName.value = user.email?.split('@').first ?? 'User';
        }

        // Set avatar URL from database
        avatarUrl.value = response['photo_url']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Fallback ke email jika ada error
      final user = _supabaseService.currentUser;
      if (user?.email != null) {
        userName.value = user!.email!.split('@').first;
      }
    } finally {
      isLoadingUser.value = false;
    }
  }

  // Fungsi untuk buka Gemini AI
  Future<void> openGeminiAI() async {
    try {
      // Buka Gemini AI di browser
      await openGeminiInBrowser();
    } catch (e) {
      debugPrint('Error opening Gemini AI: $e');
      openGeminiInBrowser();
    }
  }

  Future<void> openGeminiInBrowser() async {
    final url = Uri.parse('https://gemini.google.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openPlayStore() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.google.android.apps.bard',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Mengambil tugas hari ini dari Supabase
  Future<void> _loadTodayTasks() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final user = _supabaseService.currentUser;
      if (user == null) {
        debugPrint('User not logged in, cannot load tasks');
        return;
      }

      // ===== RECONCILE STREAK FOR NEW DAY =====
      // Check if it's a new day and reconcile streak accordingly
      final now = DateTime.now();
      final todayIso =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      if (Get.isRegistered<StreakController>()) {
        try {
          final streakController = Get.find<StreakController>();
          await streakController.reconcileForToday(todayIso);
          debugPrint(
            '[HomeController] Streak reconciliation completed for $todayIso',
          );
        } catch (e) {
          debugPrint('[HomeController] Error during streak reconciliation: $e');
        }
      }

      // Load schedules dari ScheduleController jika belum loaded
      if (_scheduleController.schedules.isEmpty) {
        await _scheduleController.fetchSchedules();
      }

      // Update today tasks dari schedule controller
      updateTodayTasksFromSchedule();

      // Restore completion status for today from local cache
      _restoreTodayCompletion();

      // Reset hitungan tugas yang sudah selesai
      completedTasksCount.value = todayTasks
          .where((task) => task['isCompleted'] == true)
          .length;

      // Update daily progress on load
      _updateDailyProgress();

      debugPrint('Loaded ${todayTasks.length} tasks for today');
    } catch (e) {
      debugPrint('Error loading today tasks: $e');
      // Jika error, tetap kosongkan tasks
      todayTasks.clear();
      completedTasksCount.value = 0;
    }
  }

  // Toggle status tugas (hanya di memori, tidak persist ke database)
  void toggleTaskCompletion(int index) {
    if (index >= 0 && index < todayTasks.length) {
      final task = todayTasks[index];
      final newStatus = !(task['isCompleted'] ?? false);

      // Update di list lokal saja
      todayTasks[index]['isCompleted'] = newStatus;
      todayTasks.refresh();

      // Update hitungan tugas yang selesai
      completedTasksCount.value = todayTasks
          .where((task) => task['isCompleted'] == true)
          .length;

      _persistTodayCompletion();

      // Auto-update daily progress untuk streak
      _updateDailyProgress();

      debugPrint(
        'Task ${task['title']} marked as ${newStatus ? "completed" : "incomplete"}',
      );
    }
  }

  // Update daily progress based on completed tasks
  void _updateDailyProgress() {
    final totalTasks = todayTasks.length;
    final completedTasks = completedTasksCount.value;
    final progressPercentage = totalTasks > 0
        ? (completedTasks / totalTasks) * 100.0
        : 0.0;

    // Update streak progress with completed task count
    // This syncs to database via StreakController._syncToDatabase()
    StreakHelper.setProgress(
      progressPercentage,
      completedTaskCount: completedTasks,
    );

    debugPrint(
      '[HomeController] Daily progress updated: ${progressPercentage.toStringAsFixed(1)}% ($completedTasks/$totalTasks tasks)',
    );
  }

  // Refresh semua data
  Future<void> refreshData() async {
    await Future.wait([_loadUserData(), _loadTodayTasks()]);
  }

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _persistTodayCompletion() {
    if (_prefs == null) return;
    final key = 'home_tasks_status_${_todayKey()}';
    final statuses = todayTasks
        .map(
          (t) => {
            'title': t['title'],
            'isCompleted': t['isCompleted'] ?? false,
          },
        )
        .toList();
    _prefs!.setString(key, jsonEncode(statuses));
  }

  void _restoreTodayCompletion() {
    if (_prefs == null) return;
    final key = 'home_tasks_status_${_todayKey()}';
    final raw = _prefs!.getString(key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final statusMap = <String, bool>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final title = item['title']?.toString();
          final val = item['isCompleted'] == true;
          if (title != null) statusMap[title] = val;
        }
      }

      for (var i = 0; i < todayTasks.length; i++) {
        final t = todayTasks[i];
        final title = t['title']?.toString();
        if (title != null && statusMap.containsKey(title)) {
          todayTasks[i]['isCompleted'] = statusMap[title];
        }
      }
      todayTasks.refresh();
    } catch (_) {
      // ignore parsing errors; fallback to unchecked tasks
    }
  }
}
