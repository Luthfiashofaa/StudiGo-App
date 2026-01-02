import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/streak/daily_mission_controller.dart';
import '../shell/app_shell.dart';

/// Daily Mission view — layout preserved, data now comes from controller
/// with daily randomized missions.
class DailyMissionView extends StatelessWidget {
  DailyMissionView({Key? key})
    : controller = Get.put(DailyMissionController()),
      super(key: key);

  final DailyMissionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Daily Mission',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Obx(() {
            final items = controller.missions;
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final m = items[index];
                return _MissionCard(
                  title: m.title,
                  current: m.progress,
                  total: m.total,
                  iconData: m.icon,
                  onTap: () => controller.markMissionComplete(m.id),
                );
              },
            );
          }),
        ),
      ),
      bottomNavigationBar: Container(
        height: 86,
        decoration: const BoxDecoration(
          color: Color(0xFF2D7DF6),
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
                IconButton(
                  onPressed: () =>
                      Get.offAll(() => const AppShell(initialIndex: 0)),
                  icon: const Icon(Icons.home, color: Colors.white, size: 28),
                ),
                IconButton(
                  onPressed: () =>
                      Get.offAll(() => const AppShell(initialIndex: 1)),
                  icon: const Icon(Icons.event, color: Colors.white, size: 28),
                ),
                IconButton(
                  onPressed: () =>
                      Get.offAll(() => const AppShell(initialIndex: 2)),
                  icon: const Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Get.offAll(() => const AppShell(initialIndex: 3)),
                  icon: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final int current;
  final int total;
  final IconData iconData;
  final VoidCallback? onTap;

  const _MissionCard({
    Key? key,
    required this.title,
    required this.current,
    required this.total,
    required this.iconData,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon / image on the left
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(iconData, size: 34, color: const Color(0xFF2B6CE4)),
              ),
            ),
            const SizedBox(width: 16),

            // Title + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress bar with percentage label to the right
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final prog = (total > 0) ? (current / total) : 0.0;
                            return Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6E6E6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                Container(
                                  width: (width * prog).clamp(0.0, width),
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4B7CF0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Fraction text near the progress bar (e.g. 1/1)
                      Text(
                        '$current/$total',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
