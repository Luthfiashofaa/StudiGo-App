import 'package:get/get.dart';
import 'streak_controller.dart';

/// Helper class untuk update daily progress dari mana saja dalam app
class StreakHelper {
  static StreakController? _getController() {
    if (Get.isRegistered<StreakController>()) {
      return Get.find<StreakController>();
    }
    return null;
  }

  /// Tambahkan progress ke hari ini (0-100)
  /// Contoh: StreakHelper.addProgress(25.0) -> tambah 25%
  static Future<void> addProgress(double amount) async {
    final controller = _getController();
    if (controller == null) return;

    await controller.restoreFromStorage();
    final currentProgress = controller.todayProgress.value;
    final newProgress = (currentProgress + amount).clamp(0.0, 100.0);
    await controller.updateTodayProgress(newProgress);
  }

  /// Set progress hari ini langsung (0-100)
  /// Contoh: StreakHelper.setProgress(100.0) -> set ke 100%
  static Future<void> setProgress(
    double progress, {
    int? completedTaskCount,
  }) async {
    final controller = _getController();
    if (controller == null) return;

    await controller.updateTodayProgress(
      progress,
      completedTaskCount: completedTaskCount,
    );
  }

  /// Get progress hari ini
  static double getTodayProgress() {
    final controller = _getController();
    return controller?.todayProgress.value ?? 0.0;
  }

  /// Cek apakah hari ini sudah 100%
  static bool isCompletedToday() {
    final controller = _getController();
    return (controller?.todayProgress.value ?? 0.0) >= 100.0;
  }

  /// Get current streak count
  static int getStreakCount() {
    final controller = _getController();
    return controller?.streakCount.value ?? 0;
  }
}
