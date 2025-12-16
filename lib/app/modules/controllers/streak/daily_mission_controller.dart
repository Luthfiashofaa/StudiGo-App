import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import '../models/daily_mission_model.dart';
import '../services/mission_service.dart';
import '../services/notification_service.dart';
import '../services/streak_service.dart';
import 'streak_controller.dart';

class DailyMissionController extends GetxController with GetTickerProviderStateMixin {
  // Services
  final MissionService _missionService = Get.find<MissionService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final StreakService _streakService = Get.find<StreakService>();
  final StreakController _streakController = Get.find<StreakController>();

  // Observable state
  final missions = <DailyMission>[].obs;
  final completedMissions = <String>[].obs;
  final totalPoints = 0.obs;
  final dailyProgress = 0.0.obs;
  final isLoading = false.obs;
  final showCelebration = false.obs;
  
  // Animation controllers
  late AnimationController progressAnimationController;
  late AnimationController celebrationController;
  late ConfettiController confettiController;
  
  // Animation
  late Animation<double> progressAnimation;
  late Animation<double> scaleAnimation;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _loadDailyMissions();
    _loadCompletedMissions();
    _setupMissionReminders();
  }

  void _initializeAnimations() {
    // Progress animation
    progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: progressAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Celebration animation
    celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: celebrationController,
        curve: Curves.elasticOut,
      ),
    );

    // Confetti controller
    confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _loadDailyMissions() async {
    try {
      isLoading.value = true;
      final loadedMissions = await _missionService.getDailyMissions();
      missions.value = loadedMissions;
      _calculateProgress();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat misi harian',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCompletedMissions() async {
    final completed = await _missionService.getCompletedMissionsToday();
    completedMissions.value = completed;
    _calculateProgress();
  }

  void _setupMissionReminders() {
    // Schedule notification untuk mengingatkan misi belum selesai
    _notificationService.scheduleMissionReminder(
      title: '🎯 Jangan Lupa Misi Harianmu!',
      body: 'Kamu masih punya ${_getIncompleteMissionsCount()} misi yang belum selesai',
      scheduledTime: DateTime.now().add(const Duration(hours: 6)),
    );
  }

  int _getIncompleteMissionsCount() {
    return missions.where((m) => !m.isCompleted).length;
  }

  void _calculateProgress() {
    if (missions.isEmpty) {
      dailyProgress.value = 0.0;
      return;
    }
    
    final completed = missions.where((m) => m.isCompleted).length;
    final newProgress = completed / missions.length;
    
    // Animate progress change
    final currentProgress = dailyProgress.value;
    progressAnimation = Tween<double>(
      begin: currentProgress,
      end: newProgress,
    ).animate(
      CurvedAnimation(
        parent: progressAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    progressAnimationController.forward(from: 0.0);
    
    // Update observable after animation
    Future.delayed(const Duration(milliseconds: 100), () {
      dailyProgress.value = newProgress;
    });
    
    // Calculate total points
    totalPoints.value = missions
        .where((m) => m.isCompleted)
        .fold(0, (sum, mission) => sum + mission.points);
  }

  Future<void> completeMission(String missionId) async {
    try {
      final missionIndex = missions.indexWhere((m) => m.id == missionId);
      if (missionIndex == -1) return;

      final mission = missions[missionIndex];
      
      // Prevent double completion
      if (mission.isCompleted) return;

      // Haptic feedback
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }

      // Update mission status
      mission.isCompleted = true;
      mission.completedAt = DateTime.now();
      missions[missionIndex] = mission;
      completedMissions.add(missionId);

      // Save to database
      await _missionService.completeMission(missionId);

      // Update progress
      _calculateProgress();

      // Add points with animation
      _animatePointsGain(mission.points);

      // Update streak
      await _streakController.updateStreakOnMissionComplete();

      // Show success feedback
      _showCompletionFeedback(mission);

      // Check if all missions completed
      if (_areAllMissionsCompleted()) {
        await _handleAllMissionsCompleted();
      }

      // Notify listeners
      update();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyelesaikan misi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void _animatePointsGain(int points) {
    celebrationController.forward(from: 0.0).then((_) {
      celebrationController.reverse();
    });

    // Show floating points animation
    Get.dialog(
      Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                '+$points XP',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Auto dismiss after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      Get.back();
    });
  }

  void _showCompletionFeedback(DailyMission mission) {
    Get.snackbar(
      '🎉 Misi Selesai!',
      '${mission.title} - +${mission.points} XP',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white, size: 32),
      duration: const Duration(seconds: 2),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      animationDuration: const Duration(milliseconds: 500),
    );
  }

  bool _areAllMissionsCompleted() {
    return missions.isNotEmpty && 
           missions.every((mission) => mission.isCompleted);
  }

  Future<void> _handleAllMissionsCompleted() async {
    // Show confetti
    confettiController.play();
    showCelebration.value = true;

    // Calculate bonus points
    const bonusPoints = 100;
    totalPoints.value += bonusPoints;

    // Update streak with bonus
    await _streakService.addBonusForAllMissionsCompleted();

    // Show celebration dialog
    await Get.dialog(
      Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                const Text(
                  '🎊 PERFECT DAY! 🎊',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Semua misi hari ini selesai!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Bonus: +$bonusPoints XP',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    showCelebration.value = false;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Luar Biasa!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Send celebration notification
    await _notificationService.sendLocalNotification(
      title: '🏆 Perfect Day Achievement!',
      body: 'Kamu menyelesaikan semua misi hari ini! +$bonusPoints XP Bonus',
    );
  }

  Future<void> refreshMissions() async {
    await _loadDailyMissions();
    await _loadCompletedMissions();
  }

  Future<void> skipMission(String missionId, {int skipCost = 50}) async {
    if (totalPoints.value < skipCost) {
      Get.snackbar(
        '⚠️ Poin Tidak Cukup',
        'Kamu memerlukan $skipCost XP untuk skip misi ini',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Skip Misi?'),
        content: Text(
          'Apakah kamu yakin ingin skip misi ini?\n\nBiaya: $skipCost XP',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      totalPoints.value -= skipCost;
      await _missionService.skipMission(missionId);
      
      final missionIndex = missions.indexWhere((m) => m.id == missionId);
      if (missionIndex != -1) {
        missions[missionIndex].isSkipped = true;
        update();
      }

      Get.snackbar(
        '⏭️ Misi Di-skip',
        'Misi berhasil di-skip. -$skipCost XP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  List<DailyMission> getActiveMissions() {
    return missions.where((m) => !m.isCompleted && !m.isSkipped).toList();
  }

  List<DailyMission> getCompletedMissionsToday() {
    return missions.where((m) => m.isCompleted).toList();
  }

  double getCompletionPercentage() {
    return dailyProgress.value * 100;
  }

  String getMotivationalMessage() {
    final percentage = getCompletionPercentage();
    
    if (percentage == 0) {
      return '🌅 Ayo mulai hari dengan misi pertama!';
    } else if (percentage < 25) {
      return '💪 Langkah bagus! Terus semangat!';
    } else if (percentage < 50) {
      return '🔥 Kamu sudah separuh jalan!';
    } else if (percentage < 75) {
      return '⭐ Luar biasa! Tinggal sedikit lagi!';
    } else if (percentage < 100) {
      return '🚀 Hampir selesai! Kamu bisa!';
    } else {
      return '🏆 Perfect! Kamu luar biasa hari ini!';
    }
  }

  @override
  void onClose() {
    progressAnimationController.dispose();
    celebrationController.dispose();
    confettiController.dispose();
    super.onClose();
  }
}
