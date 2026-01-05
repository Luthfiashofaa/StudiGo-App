import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../streak/daily_progress_card.dart';

class HomeView extends GetView<HomeController> {
  HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 600;
          final double horizontalPadding = isTablet ? 48.0 : 20.0;
          final double topPadding = isTablet ? 28.0 : 20.0;
          final double bottomScrollPadding = isTablet ? 140.0 : 110.0;
          final double maxContentWidth = double.infinity;
          final double avatarRadius = isTablet ? 34.0 : 28.0;
          final double helloFontSize = isTablet ? 22.0 : 20.0;
          final double nameFontSize = isTablet ? 28.0 : 24.0;
          final double promptFontSize = isTablet ? 24.0 : 20.0;
          final double sectionTitleSize = isTablet ? 22.0 : 18.0;

          return Stack(
            children: [
              // Animated gradient background blobs
              Positioned(
                top: -50,
                left: -80,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4A90E2).withOpacity(0.15),
                        const Color(0xFF4A90E2).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                right: -100,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.12),
                        const Color(0xFF8B5CF6).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -70,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.08),
                        const Color(0xFF10B981).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -120,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.06),
                        const Color(0xFFF59E0B).withOpacity(0.0),
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
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF4A90E2),
                                              const Color(0xFF8B5CF6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF4A90E2,
                                              ).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: CircleAvatar(
                                          radius: avatarRadius,
                                          backgroundColor: Colors.white,
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
                                                  color: const Color(
                                                    0xFF4A90E2,
                                                  ),
                                                ),
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
                                              color: Colors.black54,
                                              fontFamily: 'LieblingMedium',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                                  colors: [
                                                    Color(0xFF4A90E2),
                                                    Color(0xFF8B5CF6),
                                                  ],
                                                ).createShader(bounds),
                                            child: Text(
                                              controller.userName.value,
                                              style: TextStyle(
                                                fontSize: nameFontSize,
                                                fontFamily: 'LieblingBold',
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
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
                                Obx(
                                  () => GestureDetector(
                                    onTap: () => controller.openGeminiAI(),
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1E293B),
                                            Color(0xFF334155),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF1E293B,
                                            ).withOpacity(0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child:
                                                controller
                                                    .isGeneratingSuggestion
                                                    .value
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            Colors.amber
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.auto_awesome,
                                                    color: Colors.amber,
                                                    size: 24,
                                                  ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  controller.aiSuggestion.value,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.4,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Tap untuk buka Gemini AI',
                                                      style: TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.arrow_forward,
                                                      color: Colors.amber,
                                                      size: 14,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.95),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4A90E2,
                                        ).withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 1,
                                        offset: const Offset(0, -1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF4A90E2),
                                                  Color(0xFF357ABD),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.timeline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Progress',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Dari target harian yang tercapai',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF4A90E2),
                                                    Color(0xFF357ABD),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${controller.progressPercentage}%',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Obx(
                                        () => Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  color: const Color(
                                                    0xFFE8F4FF,
                                                  ),
                                                ),
                                                FractionallySizedBox(
                                                  widthFactor:
                                                      controller.progressValue,
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                    0xFF4A90E2,
                                                                  ),
                                                                  Color(
                                                                    0xFF8B5CF6,
                                                                  ),
                                                                ],
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 26),
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: sectionTitleSize + 4,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF4A90E2),
                                            Color(0xFF8B5CF6),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tugas Hari ini',
                                      style: TextStyle(
                                        fontSize: sectionTitleSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 52 : 48,
            height: isTablet ? 52 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A90E2).withOpacity(0.15),
                  const Color(0xFF8B5CF6).withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90E2).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4A90E2),
              size: isTablet ? 26 : 24,
            ),
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCompleted
                  ? const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    )
                  : null,
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.white : Colors.grey.shade400,
                size: isTablet ? 28 : 26,
              ),
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
