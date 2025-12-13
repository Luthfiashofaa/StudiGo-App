import 'package:get/get.dart';
import '../../../data/services/supabase_service.dart';
import '../schedule/schedule_controller.dart';

class HomeController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  late final ScheduleController _scheduleController;
  
  // Observable untuk menyimpan nama user
  final userName = 'User'.obs;
  final isLoadingUser = true.obs;
  
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
  
  // Mengambil tugas hari ini dari Supabase
  Future<void> _loadTodayTasks() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        print('User not logged in, cannot load tasks');
        return;
      }
      
      // Load schedules dari ScheduleController jika belum loaded
      if (_scheduleController.schedules.isEmpty) {
        await _scheduleController.fetchSchedules();
      }
      
      // Update today tasks dari schedule controller
      _updateTodayTasksFromSchedule();
      
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
      completedTasksCount.value = todayTasks.where((task) => task['isCompleted'] == true).length;
      
      print('Task ${task['title']} marked as ${newStatus ? "completed" : "incomplete"}');
    }
  }
  
  // Refresh semua data
  Future<void> refreshData() async {
    await Future.wait([
      _loadUserData(),
      _loadTodayTasks(),
    ]);
  }
}
