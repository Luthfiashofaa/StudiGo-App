import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/shell/shell_controller.dart';
import '../../controllers/home/home_controller.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../views/home/home_view.dart';
import '../../views/schedule/schedule_view.dart';
import '../../views/schedule/add_schedule_view.dart';
import '../../views/streak/streak_view.dart';
import '../../views/profile/profile_view.dart';
import '../../../data/services/notification_service.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ShellController _shellController;

  final List<Widget> _pages = [
    HomeView(),
    const ScheduleView(),
    const StreakView(),
    const ProfileView(),
  ];

  void _onTap(int idx) => _shellController.setIndex(idx);

  Future<void> _navigateToAddSchedule() async {
    // Navigate to add schedule and wait for return value (tab index)
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const AddScheduleView()),
    );

    // If user selected a different tab from navbar in add schedule, switch to it
    if (result != null) {
      _shellController.setIndex(result);
    }
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const activeBoxColor = Color(0xFF6097FF); // #6097FF untuk kotak aktif
    return Container(
      width: 50,
      height: 50,
      decoration: isActive
          ? BoxDecoration(
              color: activeBoxColor,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      alignment: Alignment.center,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 56, height: 56),
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 32,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _shellController = Get.put(ShellController());
    _shellController.setIndex(widget.initialIndex);
    // Ensure HomeController is available for HomeView
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    }
    // Ensure ProfileController is available for ProfileView
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    }
    // Request notification permissions
    _requestNotificationPermission();
  }

  /// Request notification permission from user
  Future<void> _requestNotificationPermission() async {
    try {
      final notificationService = NotificationService();
      final granted = await notificationService.requestPermissions();
      if (granted) {
        debugPrint('[AppShell] Notification permissions granted');
      } else {
        debugPrint('[AppShell] Notification permissions denied');
      }
    } catch (e) {
      debugPrint('[AppShell] Error requesting notification permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1557D4);

    return Scaffold(
      body: SafeArea(
        child: Obx(() => _pages[_shellController.currentIndex.value]),
      ),
      bottomNavigationBar: Container(
        height: 86,
        decoration: const BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(
                  () => _buildNavIcon(
                    icon: Icons.home,
                    isActive: _shellController.currentIndex.value == 0,
                    onTap: () => _onTap(0),
                  ),
                ),
                Obx(
                  () => _buildNavIcon(
                    icon: Icons.event,
                    isActive: _shellController.currentIndex.value == 1,
                    onTap: () => _onTap(1),
                  ),
                ),
                Obx(
                  () => _buildNavIcon(
                    icon: Icons.track_changes,
                    isActive: _shellController.currentIndex.value == 2,
                    onTap: () => _onTap(2),
                  ),
                ),
                Obx(
                  () => _buildNavIcon(
                    icon: Icons.person,
                    isActive: _shellController.currentIndex.value == 3,
                    onTap: () => _onTap(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// _Placeholder removed — replaced by real pages (ScheduleView etc.)
