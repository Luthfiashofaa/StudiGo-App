import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'daily_mission_view.dart';

import '../../controllers/streak/streak_controller.dart';

class StreakView extends StatefulWidget {
  const StreakView({Key? key}) : super(key: key);

  @override
  State<StreakView> createState() => _StreakViewState();
}

class _StreakViewState extends State<StreakView> {
  late StreakController controller;
  bool showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // ensure controller available (AppShell may not have bound it)
    if (!Get.isRegistered<StreakController>()) {
      Get.lazyPut<StreakController>(() => StreakController());
    }
    controller = Get.find<StreakController>();

    // Setup scroll listener in initState, not in build
    controller.scrollController.addListener(_onScrollChanged);

    // Setup initial scroll position after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollToCurrentDay();
    });
  }

  void _autoScrollToCurrentDay() {
    if (!controller.hasAutoScrolled && controller.scrollController.hasClients) {
      const segmentHeight = 320.0;
      const int baseFutureDays = 100;
      final totalDays = baseFutureDays + controller.streakCount.value;

      final viewport = MediaQuery.of(context).size.height;
      final currentIndex = (controller.streakCount.value - 1).clamp(
        0,
        totalDays - 1,
      );
      final contentHeight = (totalDays * segmentHeight).clamp(
        segmentHeight * 1.5,
        200000.0,
      );
      // compute the cy in bottom-origin coordinate
      final cy = contentHeight - (currentIndex * segmentHeight + 150.0);
      final target = (cy - viewport / 2).clamp(
        0.0,
        controller.scrollController.position.maxScrollExtent,
      );
      controller.scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
      controller.hasAutoScrolled = true;
    }
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onScrollChanged() {
    final offset = controller.scrollController.offset;
    final newValue = offset > 200;
    // Only call setState if value actually changed to avoid unnecessary rebuilds
    if (showScrollToTop != newValue) {
      setState(() {
        showScrollToTop = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

          final contentHeight = (totalDays * segmentHeight).clamp(
            segmentHeight * 1.5,
            200000.0,
          );

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
                            houses: ctrl.houses.toList(),
                            selectedHouseIndex: ctrl.selectedHouseIndex.value,
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

              // Show/hide scroll-to-top button based on scroll position
              if (showScrollToTop)
                Positioned(
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
                ),

              Positioned(
                right: 24,
                bottom: 25,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Daily Mission screen when trophy is tapped
                    Get.to(() => const DailyMissionView());
                  },
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
  final List<String> houses;
  final int selectedHouseIndex;

  _WavyPathPainter({
    this.days = 20,
    this.currentDay = 1,
    this.houses = const <String>[],
    this.selectedHouseIndex = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF7CD86B).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 65
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final segmentH = 320.0;

    // (Decorations will be drawn after we compute xForY so they can follow the path)

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

    // (Decorations will be drawn after we compute and draw the path so they
    // can be layered above the road but still below the nodes.)

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

    // Precompute node centers so decorations (houses/trees) can avoid them.
    final nodeCenters = <Offset>[];
    for (int i = 0; i < days; i++) {
      final cy = size.height - (i * segmentH + 150.0);
      final cx = xForY(cy);
      nodeCenters.add(Offset(cx, cy));
    }

    // Draw houses along the path (like trees) using precomputed samples.
    void drawHouse(
      Canvas canvas,
      double cx,
      double cy,
      double scale,
      String name,
      bool selected,
    ) {
      // House base
      final houseW = 34.0 * scale;
      final houseH = 22.0 * scale;
      final basePaint = Paint()
        ..color = selected ? Colors.white : const Color(0xFFEDDFB8);
      final roofPaint = Paint()
        ..color = selected ? const Color(0xFF47CF5B) : const Color(0xFFCC6A3C);

      final rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: houseW,
        height: houseH,
      );
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rRect, basePaint);

      // Roof triangle
      final roof = Path()
        ..moveTo(cx - houseW / 2 - 2, cy - houseH / 2)
        ..lineTo(cx + houseW / 2 + 2, cy - houseH / 2)
        ..lineTo(cx, cy - houseH / 2 - (10.0 * scale))
        ..close();
      canvas.drawPath(roof, roofPaint);

      // Optional small label (shortened)
      final label = TextPainter(
        text: TextSpan(
          text: name.length > 10 ? name.substring(0, 10) + '…' : name,
          style: TextStyle(
            color: selected ? Colors.black87 : Colors.white,
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80 * scale);
      label.paint(
        canvas,
        Offset(cx - label.width / 2, cy + houseH / 2 + 4 * scale),
      );
    }

    // Place houses if available
    if (houses.isNotEmpty && samples.length >= 2) {
      final placed = <Offset>[];
      final rand = math.Random(9876);
      final nodeAvoid = 70.0;
      final minSpacing = 56.0;
      final target = houses.length;
      final denom = (target - 1).clamp(1, samples.length - 1);

      for (int t = 0; t < target; t++) {
        final idxDouble = (t * (samples.length - 1) / denom);
        int baseIdx = idxDouble.round().clamp(0, samples.length - 1);

        bool placedOne = false;
        for (int attempt = 0; attempt < 9 && !placedOne; attempt++) {
          final tryIdx = (baseIdx + (attempt - 4)).clamp(0, samples.length - 1);
          final s = samples[tryIdx];
          final dx = (rand.nextDouble() - 0.5) * 60.0;
          final cx = (s.dx + dx).clamp(16.0, w - 16.0);
          final cy = s.dy + (rand.nextDouble() - 0.5) * 18.0;
          final pos = Offset(cx, cy);

          // avoid node centers
          var bad = false;
          for (final n in nodeCenters) {
            if ((n - pos).distance < nodeAvoid) {
              bad = true;
              break;
            }
          }
          if (bad) continue;

          // avoid other houses
          for (final hpos in placed) {
            if ((hpos - pos).distance < minSpacing) {
              bad = true;
              break;
            }
          }
          if (bad) continue;

          // draw
          final scale = 0.9 + rand.nextDouble() * 0.6;
          final name = houses[t];
          final selected = t == selectedHouseIndex;
          drawHouse(canvas, cx, cy, scale, name, selected);
          placed.add(pos);
          placedOne = true;
        }
      }
    }

    // Decorative background: draw trees on top of the road but beneath the
    // day nodes so they visually sit on the path layer.
    void drawTree(Canvas canvas, double cx, double cy, double scale) {
      final foliagePaint = Paint()
        ..color = const Color(0xFF2F8C3A).withOpacity(0.16)
        ..style = PaintingStyle.fill;
      final trunkPaint = Paint()
        ..color = const Color(0xFF6B3F1F).withOpacity(0.18)
        ..style = PaintingStyle.fill;

      final h = 48.0 * scale;
      final trunkW = 8.0 * scale;
      final trunkH = 12.0 * scale;

      for (int layer = 0; layer < 3; layer++) {
        final layerTop = cy - h + layer * (h * 0.28);
        final width = h - layer * (h * 0.22);
        final p = Path()
          ..moveTo(cx, layerTop)
          ..lineTo(cx - width / 2, layerTop + width / 1.05)
          ..lineTo(cx + width / 2, layerTop + width / 1.05)
          ..close();
        canvas.drawPath(p, foliagePaint);
      }

      final rect = Rect.fromCenter(
        center: Offset(cx, cy + trunkH / 2),
        width: trunkW,
        height: trunkH,
      );
      canvas.drawRect(rect, trunkPaint);
    }

    // (Tree placement moved below so we can draw them after nodes if desired.)

    // Draw day nodes from bottom upwards: Day 1 at the bottom.
    for (int i = 0; i < nodeCenters.length; i++) {
      // use precomputed node center
      final cx = nodeCenters[i].dx;
      final cy = nodeCenters[i].dy;

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

    // Draw trees on top of the circles/nodes so they are not hidden behind
    // the day markers. We sample the precomputed `samples` path points to
    // distribute trees along the entire curved road (bottom -> top).
    // Increase sampling density and remove the tight cap so trees can
    // populate the entire curve (previous logic could stop early around
    // level ~35 due to coarse stepping and low max count).
    // Keep trees sparse: limit total trees so they don't overcrowd the path.
    final maxTreesTop = 48; // reasonable default density
    final randTop = math.Random(2345);
    if (samples.isNotEmpty) {
      // Place a small fixed number of trees evenly across the path so they
      // reach the very top and remain sparse. If a chosen spot is too close
      // to a node or another tree, try a few nearby samples before giving up.
      final drawnPositions = <Offset>[];
      const nodeAvoidDist = 80.0; // don't draw trees nearer than this to a node
      const minTreeSpacing = 70.0; // minimum distance between trees

      // Target number of trees across the whole path (kept small)
      // Reduce slightly so decorations are visible but not crowded.
      final targetTrees = math.min(maxTreesTop, 8);
      if (samples.length >= 2 && targetTrees > 0) {
        for (int t = 0; t < targetTrees; t++) {
          // evenly spaced sample index (0..samples.length-1)
          final idxDouble = (t * (samples.length - 1) / (targetTrees - 1));
          int baseIdx = idxDouble.round().clamp(0, samples.length - 1);

          bool placed = false;
          // try nearby offsets if the base spot is unsuitable
          for (int attempt = 0; attempt < 9 && !placed; attempt++) {
            final offsetIdx = (baseIdx + (attempt - 4)).clamp(
              0,
              samples.length - 1,
            );
            final s = samples[offsetIdx];
            final dx = (randTop.nextDouble() - 0.5) * 60.0;
            final ox = (s.dx + dx).clamp(16.0, w - 16.0);
            final scale = 0.35 + randTop.nextDouble() * 0.9;
            final yJitter = (randTop.nextDouble() - 0.5) * 20.0;
            final tx = ox;
            final ty = s.dy + yJitter - 10.0;
            final pos = Offset(tx, ty);

            var tooCloseToNode = false;
            for (final n in nodeCenters) {
              if ((n - pos).distance < nodeAvoidDist) {
                tooCloseToNode = true;
                break;
              }
            }
            if (tooCloseToNode) continue;

            var tooCloseToTree = false;
            for (final tpos in drawnPositions) {
              if ((tpos - pos).distance < minTreeSpacing) {
                tooCloseToTree = true;
                break;
              }
            }
            if (tooCloseToTree) continue;

            drawTree(canvas, tx, ty, scale);
            drawnPositions.add(pos);
            placed = true;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavyPathPainter old) =>
      old.days != days || old.currentDay != currentDay;
}

// (Removed custom painter; using asset `assets/fire.png` instead.)
