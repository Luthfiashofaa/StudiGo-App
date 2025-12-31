import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/supabase_service.dart';
import '../schedule/schedule_controller.dart';

class HomeController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  late final ScheduleController _scheduleController;

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

  void updateTodayTasksFromSchedule() {
    debugPrint('[HomeController] updateTodayTasksFromSchedule called');
    final now = DateTime.now();
    final todayYear = now.year;
    final todayMonth = now.month;
    final todayDay = now.day;
    debugPrint(
      '[HomeController] Today date: $todayYear-${todayMonth.toString().padLeft(2, '0')}-${todayDay.toString().padLeft(2, '0')}',
    );
    debugPrint(
      '[HomeController] Total schedules in ScheduleController: ${_scheduleController.schedules.length}',
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
    for (int i = 0; i < _scheduleController.schedules.length; i++) {
      final item = _scheduleController.schedules[i];
      debugPrint(
        '[HomeController] Schedule[$i]: title=${item['title']}, start_time_raw=${item['start_time']}',
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

    final todaySchedules = _scheduleController.schedules.where((item) {
      final dt = parseLocal(item['start_time']);
      if (dt == null) {
        return false;
      }
      final match =
          dt.year == todayYear && dt.month == todayMonth && dt.day == todayDay;
      return match;
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
            .single();

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
      final user = _supabaseService.currentUser;
      if (user == null) {
        debugPrint('User not logged in, cannot load tasks');
        return;
      }
      // Load schedules dari ScheduleController jika belum loaded
      if (_scheduleController.schedules.isEmpty) {
        await _scheduleController.fetchSchedules();
      }

      // Update today tasks dari schedule controller
      updateTodayTasksFromSchedule();

      // Reset hitungan tugas yang sudah selesai
      completedTasksCount.value = 0;

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

      debugPrint(
        'Task ${task['title']} marked as ${newStatus ? "completed" : "incomplete"}',
      );
    }
  }

  // Refresh semua data
  Future<void> refreshData() async {
    await Future.wait([_loadUserData(), _loadTodayTasks()]);
  }
}
