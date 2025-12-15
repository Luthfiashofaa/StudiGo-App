import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';

class HomeView extends GetView<HomeController> {
  HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 600;
          final double horizontalPadding = isTablet ? 32.0 : 20.0;
          final double topPadding = isTablet ? 28.0 : 20.0;
          final double bottomScrollPadding = isTablet ? 140.0 : 110.0;
          final double maxContentWidth = isTablet ? 900.0 : double.infinity;
          final double avatarRadius = isTablet ? 34.0 : 28.0;
          final double helloFontSize = isTablet ? 22.0 : 20.0;
          final double nameFontSize = isTablet ? 28.0 : 24.0;
          final double promptFontSize = isTablet ? 24.0 : 20.0;
          final double sectionTitleSize = isTablet ? 22.0 : 18.0;

          return Stack(
            children: [
              Positioned(
                top: 180,
                left: -70,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.11),
                        Colors.blue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 150,
                right: -90,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.1),
                        Colors.purple.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 150,
                left: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.05),
                        Colors.blue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.04),
                        Colors.blue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              topPadding,
                              horizontalPadding,
                              bottomScrollPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Obx(() {
                                      final hasAvatar =
                                          controller.avatarUrl.value.isNotEmpty;
                                      return CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundColor: const Color(
                                          0xFFEEF6FF,
                                        ),
                                        backgroundImage: hasAvatar
                                            ? NetworkImage(
                                                controller.avatarUrl.value,
                                              )
                                            : null,
                                        child: hasAvatar
                                            ? null
                                            : Icon(
                                                Icons.person,
                                                size: avatarRadius,
                                                color: Colors.blue,
                                              ),
                                      );
                                    }),
                                    const SizedBox(width: 12),
                                    Obx(() {
                                      if (controller.isLoadingUser.value) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Halo!',
                                              style: TextStyle(
                                                fontSize: helloFontSize,
                                                color: Colors.black,
                                                fontFamily: 'LieblingMedium',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const SizedBox(
                                              width: 100,
                                              height: 24,
                                              child: LinearProgressIndicator(),
                                            ),
                                          ],
                                        );
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Halo!',
                                            style: TextStyle(
                                              fontSize: helloFontSize,
                                              color: Colors.black,
                                              fontFamily: 'LieblingMedium',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            controller.userName.value,
                                            style: TextStyle(
                                              fontSize: nameFontSize,
                                              fontFamily: 'LieblingBold',
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Siap capai targetmu hari ini ?',
                                  style: TextStyle(
                                    fontSize: promptFontSize,
                                    fontFamily: 'LieblingBold',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                GestureDetector(
                                  onTap: () => controller.openGeminiAI(),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                'AI menyarankan kamu fokus pada tugas "Kalkulus" hari ini',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Tap untuk buka Gemini AI',
                                                style: TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Progress',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Dari target harian yang tercapai',
                                              style: TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              '${controller.progressPercentage}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Obx(
                                        () => ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            minHeight: 10,
                                            value: controller.progressValue,
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Colors.blue),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 26),
                                Text(
                                  'Tugas Hari ini',
                                  style: TextStyle(
                                    fontSize: sectionTitleSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Obx(() {
                                  if (controller.todayTasks.isEmpty) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Text(
                                          'Tidak ada tugas hari ini',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (isTablet) {
                                    return GridView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: controller.todayTasks.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 3.2,
                                          ),
                                      itemBuilder: (context, index) {
                                        final task =
                                            controller.todayTasks[index];
                                        return _TaskCard(
                                          icon: _getIconForTask(
                                            task['title'] ?? 'Task',
                                          ),
                                          title:
                                              task['title'] ??
                                              'Task ${index + 1}',
                                          isCompleted:
                                              task['isCompleted'] ?? false,
                                          onToggle: () => controller
                                              .toggleTaskCompletion(index),
                                          isTablet: true,
                                        );
                                      },
                                    );
                                  }
                                  return Column(
                                    children: List.generate(
                                      controller.todayTasks.length,
                                      (index) {
                                        final task =
                                            controller.todayTasks[index];
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom:
                                                index <
                                                    controller
                                                            .todayTasks
                                                            .length -
                                                        1
                                                ? 12
                                                : 0,
                                          ),
                                          child: _TaskCard(
                                            icon: _getIconForTask(
                                              task['title'] ?? 'Task',
                                            ),
                                            title:
                                                task['title'] ??
                                                'Task ${index + 1}',
                                            isCompleted:
                                                task['isCompleted'] ?? false,
                                            onToggle: () => controller
                                                .toggleTaskCompletion(index),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isCompleted;
  final VoidCallback onToggle;
  final bool isTablet;

  const _TaskCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.isCompleted,
    required this.onToggle,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          // soft centered glow to give an even halo
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            spreadRadius: 1.2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 48 : 44,
            height: isTablet ? 48 : 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue, size: isTablet ? 24 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.blue : Colors.grey,
              size: isTablet ? 28 : 26,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function untuk mendapatkan icon berdasarkan judul task
IconData _getIconForTask(String title) {
  final lowerTitle = title.toLowerCase();
  if (lowerTitle.contains('kalkulus') ||
      lowerTitle.contains('math') ||
      lowerTitle.contains('matematika')) {
    return Icons.calculate;
  } else if (lowerTitle.contains('programming') ||
      lowerTitle.contains('code') ||
      lowerTitle.contains('coding')) {
    return Icons.code;
  } else if (lowerTitle.contains('fisika') || lowerTitle.contains('physics')) {
    return Icons.science;
  } else if (lowerTitle.contains('bahasa') || lowerTitle.contains('language')) {
    return Icons.book;
  } else if (lowerTitle.contains('lab') || lowerTitle.contains('praktikum')) {
    return Icons.biotech;
  } else {
    return Icons.assignment;
  }
}
