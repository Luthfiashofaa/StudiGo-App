import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/streak/streak_controller.dart';

/// Widget untuk menampilkan daily progress bar
/// Bisa diletakkan di mana saja (home, profile, dll)
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get streak controller
    final controller = Get.isRegistered<StreakController>()
        ? Get.find<StreakController>()
        : Get.put(StreakController());

    return Obx(() {
      final progress = controller.todayProgress.value;
      final isComplete = progress >= 100.0;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF47CF5B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.whatshot,
                        color: Color(0xFF47CF5B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${controller.streakCount.value} day streak',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isComplete
                        ? const Color(0xFF47CF5B)
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress / 100.0,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF47CF5B), Color(0xFF6FDC8C)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF47CF5B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status text
            Text(
              isComplete
                  ? '🎉 Complete! Keep the streak going tomorrow!'
                  : 'Keep going! You\'re ${(100 - progress).toInt()}% away from completing today.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }
}
