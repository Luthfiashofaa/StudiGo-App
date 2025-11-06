import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/streak/streak_controller.dart';

class StreakView extends GetView<StreakController> {
  const StreakView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ensure controller available (AppShell may not have bound it)
    if (!Get.isRegistered<StreakController>()) {
      Get.lazyPut<StreakController>(() => StreakController());
    }

    final ctrl = controller;

    return Scaffold(
      backgroundColor: const Color(0xFF47CF5B),
      body: SafeArea(
        child: Obx(() {
          const segmentHeight = 320.0;
          // base number of future days after Day 1
          const int baseFutureDays = 100;
          // compute total days as base + current streak day
          final totalDays = baseFutureDays + ctrl.streakCount.value;
          // ensure controller.days reflects this total so painter and loadMore agree
          if (ctrl.days.value != totalDays) {
            ctrl.days.value = totalDays;
          }
          final contentHeight = (totalDays * segmentHeight).clamp(
            segmentHeight * 1.5,
            200000.0,
          );

          // Listen to scroll position
          final showScrollToTop = false.obs;
          ctrl.scrollController.addListener(() {
            final offset = ctrl.scrollController.offset;
            showScrollToTop.value = offset > 200;
          });

          // Auto-scroll once to center the current day node
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!ctrl.hasAutoScrolled && ctrl.scrollController.hasClients) {
              final viewport = MediaQuery.of(context).size.height;
              final currentIndex = (ctrl.streakCount.value - 1).clamp(
                0,
                totalDays - 1,
              );
              // compute the cy in bottom-origin coordinate (contentHeight == size.height in painter)
              final cy = contentHeight - (currentIndex * segmentHeight + 150.0);
              final target = (cy - viewport / 2).clamp(
                0.0,
                ctrl.scrollController.position.maxScrollExtent,
              );
              ctrl.scrollController.animateTo(
                target,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
              );
              ctrl.hasAutoScrolled = true;
            }
          });

          return Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                controller: ctrl.scrollController,
                child: SizedBox(
                  width: double.infinity,
                  height: contentHeight,
                  child: Stack(
                    children: [
                      // wavy path and nodes
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WavyPathPainter(
                            days: totalDays,
                            currentDay: ctrl.streakCount.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed header (top-left) - Streak badge with flame icon
              // Fixed header (top-left) - Streak badge with flame icon
              Positioned(
                left: -10,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Flame icon with number
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Center(
                                child: Image.asset(
                                  'assets/fire.png',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Streak number on flame
                            Positioned(
                              top: 53,
                              child: Obx(
                                () => Text(
                                  '${ctrl.streakCount.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 25,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20), // Naikkan teks STREAK
                        child: const Text(
                          'STREAK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Obx(
                () => showScrollToTop.value
                    ? Positioned(
                        top: 16,
                        right: 24,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ctrl.scrollController.animateTo(
                                ctrl.scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.arrow_downward,
                                    color: Color(0xFF47CF5B),
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Day 1',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              Positioned(
                right: 24,
                bottom: 25,
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // subtle glow
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      // outer gradient ring
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD93D), Color(0xFFFFC700)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),

                      // inner ring
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF0AD28),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            color: Colors.black87,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _WavyPathPainter extends CustomPainter {
  final int days;
  final int currentDay;
  _WavyPathPainter({this.days = 20, this.currentDay = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF7CD86B).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 65
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final segmentH = 320.0;

    // Helper: compute x position for a given y using a sine-based segment shape
    // Now compute positions with origin at bottom so the visual flow goes
    // from bottom -> top. y is measured from the top (canvas coordinate),
    // so convert to yFromBottom.
    double xForY(double y) {
      final yFromBottom = (size.height - y).clamp(0.0, size.height);
      final seg = (yFromBottom / segmentH).floor();
      final local = ((yFromBottom - seg * segmentH) / segmentH).clamp(0.0, 1.0);
      final angle = local * math.pi; // 0..pi per segment -> half sine wave
      final amp = w * 0.32; // amplitude controls how far path swings
      final center = w * 0.5;
      final val = math.sin(angle);
      // alternate direction per segment starting from bottom
      return (seg % 2 == 0) ? center + amp * val : center - amp * val;
    }

    // Sample the continuous curve at small intervals and then convert to smooth
    // cubic curves using Catmull-Rom -> cubic Bezier approximation.
    final samples = <Offset>[];
    final step = 8.0; // px per sample (smaller -> smoother but heavier)
    // Sample from bottom -> top so early cap covers the bottom area (Day 1)
    for (double y = size.height; y >= 0.0; y -= step) {
      samples.add(Offset(xForY(y), y));
      if (samples.length > 6000)
        break; // safety cap (larger to cover long content)
    }

    if (samples.isNotEmpty) {
      final path = Path()..moveTo(samples[0].dx, samples[0].dy);

      // Catmull-Rom to cubic bezier
      for (int i = 0; i < samples.length - 1; i++) {
        final p0 = i - 1 >= 0 ? samples[i - 1] : samples[i];
        final p1 = samples[i];
        final p2 = samples[i + 1];
        final p3 = i + 2 < samples.length ? samples[i + 2] : samples[i + 1];

        // tension = 1/6 gives nice smooth curves
        final control1 = Offset(
          p1.dx + (p2.dx - p0.dx) / 6.0,
          p1.dy + (p2.dy - p0.dy) / 6.0,
        );
        final control2 = Offset(
          p2.dx - (p3.dx - p1.dx) / 6.0,
          p2.dy - (p3.dy - p1.dy) / 6.0,
        );

        path.cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          p2.dx,
          p2.dy,
        );
      }

      canvas.drawPath(path, pathPaint);
    }

    // Draw day nodes from bottom upwards: Day 1 at the bottom.
    for (int i = 0; i < days; i++) {
      // i == 0 -> Day 1 -> bottom-most segment
      final cy = size.height - (i * segmentH + 150.0);
      final cx = xForY(cy);

      // White outer circle with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx, cy + 2), 34, shadowPaint);

      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 34, outerPaint);

      // Gold inner circle with vertical gradient
      final innerShader = ui.Gradient.linear(
        Offset(cx, cy - 28),
        Offset(cx, cy + 28),
        [const Color(0xFFC9A546), const Color(0xFFFFD93D)],
      );
      final innerPaint = Paint()
        ..shader = innerShader
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 28, innerPaint);

      // Day text
      final dayText = TextPainter(
        text: TextSpan(
          text: 'Day ${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      dayText.paint(
        canvas,
        Offset(cx - dayText.width / 2, cy - dayText.height / 2),
      );
    }
    // Highlight the current day (1-based). Compute its cy same as above
    if (days > 0 && currentDay >= 1 && currentDay <= days) {
      final idx = (currentDay - 1);
      final cy = size.height - (idx * segmentH + 150.0);
      final cx = xForY(cy);

      // White outer circle (larger)
      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 40, outerPaint);

      // Gold inner circle (larger) with vertical gradient
      final innerShader = ui.Gradient.linear(
        Offset(cx, cy - 34),
        Offset(cx, cy + 34),
        [const Color(0xFFFFD93D), const Color(0xFFC9A546)],
      );
      final innerPaint = Paint()
        ..shader = innerShader
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 34, innerPaint);

      // Current day text
      final dayText = TextPainter(
        text: TextSpan(
          text: 'Day $currentDay',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      dayText.paint(
        canvas,
        Offset(cx - dayText.width / 2, cy - dayText.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavyPathPainter old) =>
      old.days != days || old.currentDay != currentDay;
}

// (Removed custom painter; using asset `assets/fire.png` instead.)
