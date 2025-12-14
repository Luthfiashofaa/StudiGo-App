import 'package:get/get.dart';
import '../../../data/services/supabase_service.dart';
<<<<<<< HEAD
import '../schedule/schedule_controller.dart';

class HomeController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  late final ScheduleController _scheduleController;
  
=======
import 'package:url_launcher/url_launcher.dart';

class HomeController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

>>>>>>> f5eaa84a9879144561beb822796c7883eecac260
  // Observable untuk menyimpan nama user
  final userName = 'User'.obs;
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
<<<<<<< HEAD
    _initScheduleListener();
    _loadUserData();
    _loadTodayTasks();
=======
>>>>>>> f5eaa84a9879144561beb822796c7883eecac260
  }

  void _initScheduleListener() {
    if (Get.isRegistered<ScheduleController>()) {
      _scheduleController = Get.find<ScheduleController>();
    } else {
      _scheduleController = Get.put(ScheduleController());
    }
    ever(_scheduleController.schedules, (_) {
      _updateTodayTasksFromSchedule();
    });
  }

  void _updateTodayTasksFromSchedule() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todaySchedules = _scheduleController.schedules.where((item) {
      final raw = item['start_time']?.toString();
      final dt = raw != null ? DateTime.tryParse(raw) : null;
      if (dt == null) return false;
      return dt.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          dt.isBefore(endOfDay);
    }).toList();

    todayTasks.assignAll(todaySchedules);
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

  @override
  void onClose() {
    super.onClose();
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
            .select('firstname, lastname, name')
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
      }
    } catch (e) {
      print('Error loading user data: $e');
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
      print('Error: $e');
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
        print('User not logged in, cannot load tasks');
        return;
      }
<<<<<<< HEAD
      
      // Load schedules dari ScheduleController jika belum loaded
      if (_scheduleController.schedules.isEmpty) {
        await _scheduleController.fetchSchedules();
      }
      
      // Update today tasks dari schedule controller
      _updateTodayTasksFromSchedule();
      
=======

      // Dapatkan tanggal hari ini (tanpa waktu)
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print(
        'Loading tasks for today: ${startOfDay.toString()} to ${endOfDay.toString()}',
      );

      // Query schedules untuk hari ini
      final data = await _supabaseService.client
          .from('schedules')
          .select('id, title, start_time, end_time, description, category')
          .eq('user_id', user.id)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String())
          .order('start_time', ascending: true);

      print('Received ${(data as List).length} schedules from database');

      final list = List<Map<String, dynamic>>.from(data);

      // Tambahkan properti isCompleted untuk setiap task (hanya di memori, tidak persist)
      for (var task in list) {
        task['isCompleted'] = false; // Default semua belum selesai
        task['title'] = task['title'] ?? 'Tugas'; // Fallback jika title null
      }

      todayTasks.assignAll(list);

>>>>>>> f5eaa84a9879144561beb822796c7883eecac260
      // Reset hitungan tugas yang sudah selesai
      completedTasksCount.value = 0;

      print('Loaded ${todayTasks.length} tasks for today');
    } catch (e) {
      print('Error loading today tasks: $e');
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

      print(
        'Task ${task['title']} marked as ${newStatus ? "completed" : "incomplete"}',
      );
    }
  }

  // Refresh semua data
  Future<void> refreshData() async {
    await Future.wait([_loadUserData(), _loadTodayTasks()]);
  }
}
