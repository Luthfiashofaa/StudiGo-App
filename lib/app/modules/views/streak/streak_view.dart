import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
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
      // Fetch completion status when view is opened
      _initializeStreakData();
    });
  }

  /// Initialize streak data by fetching from database
  Future<void> _initializeStreakData() async {
    debugPrint('[StreakView] Initializing streak data...');

    // Calculate today's date key
    final today = DateTime.now();
    final todayIso =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Reconcile for today (this will fetch dayCompletionStatus)
    await controller.reconcileForToday(todayIso);

    debugPrint('[StreakView] Streak data initialized');
  }

  void _autoScrollToCurrentDay() {
    if (!controller.hasAutoScrolled && controller.scrollController.hasClients) {
      const segmentHeight = 320.0;

      // Calculate current day index based on firstDayDate
      // Normalize dates to ignore time component
      final firstDay = controller.firstDayDate.value;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final firstDayNormalized = firstDay != null
          ? DateTime(firstDay.year, firstDay.month, firstDay.day)
          : null;

      int currentDayIndex;
      int totalDays;

      if (firstDayNormalized != null) {
        // Calculate days from Day 1 to today
        final daysSinceStart = today.difference(firstDayNormalized).inDays + 1;
        totalDays = daysSinceStart;
        currentDayIndex = daysSinceStart - 1; // Convert to 0-based index
      } else {
        // Fallback to streak-based calculation
        const int baseFutureDays = 100;
        totalDays = baseFutureDays + controller.streakCount.value;
        currentDayIndex = (controller.streakCount.value - 1).clamp(
          0,
          totalDays - 1,
        );
      }

      final viewport = MediaQuery.of(context).size.height;
      final contentHeight = (totalDays * segmentHeight).clamp(
        segmentHeight * 1.5,
        200000.0,
      );
      // compute the cy in bottom-origin coordinate
      final cy = contentHeight - (currentDayIndex * segmentHeight + 150.0);
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

          // Calculate total days from Day 1 to today + future days
          // Normalize dates to remove time component (only use date, ignore time)
          final firstDay = ctrl.firstDayDate.value;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Normalize firstDay to remove time as well
          final firstDayNormalized = firstDay != null
              ? DateTime(firstDay.year, firstDay.month, firstDay.day)
              : null;

          // If we have firstDay, calculate days from Day 1 to today + future days
          // Otherwise, default to showing based on streak
          final int totalDays;
          const int futureDaysToShow = 100;
          if (firstDayNormalized != null) {
            final daysSinceStart =
                today.difference(firstDayNormalized).inDays +
                1; // +1 to include today
            totalDays = daysSinceStart + futureDaysToShow;
          } else {
            // Fallback: show based on streak count + future days
            totalDays = ctrl.streakCount.value + futureDaysToShow;
          }

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
                            currentDay: firstDayNormalized != null
                                ? today.difference(firstDayNormalized).inDays +
                                      1
                                : ctrl.streakCount.value,
                            houses: ctrl.houses.toList(),
                            selectedHouseIndex: ctrl.selectedHouseIndex.value,
                            dayCompletionStatus: ctrl.dayCompletionStatus,
                            firstDayDate: firstDayNormalized,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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

              // Show/hide scroll-to-today button based on scroll position
              if (showScrollToTop)
                Positioned(
                  top: 16,
                  right: 24,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Scroll to today position
                        const segmentHeight = 320.0;
                        final firstDay = ctrl.firstDayDate.value;
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        int currentDayIndex;
                        int totalDays;

                        final firstDayNormalized = firstDay != null
                            ? DateTime(
                                firstDay.year,
                                firstDay.month,
                                firstDay.day,
                              )
                            : null;

                        if (firstDayNormalized != null) {
                          final daysSinceStart =
                              today.difference(firstDayNormalized).inDays + 1;
                          totalDays = daysSinceStart + 100;
                          currentDayIndex = daysSinceStart - 1;
                        } else {
                          totalDays = ctrl.streakCount.value + 100;
                          currentDayIndex = (ctrl.streakCount.value - 1).clamp(
                            0,
                            totalDays - 1,
                          );
                        }

                        final viewport = MediaQuery.of(context).size.height;
                        final contentHeight = (totalDays * segmentHeight).clamp(
                          segmentHeight * 1.5,
                          200000.0,
                        );
                        final cy =
                            contentHeight -
                            (currentDayIndex * segmentHeight + 150.0);
                        final target = (cy - viewport / 2).clamp(
                          0.0,
                          ctrl.scrollController.position.maxScrollExtent,
                        );

                        ctrl.scrollController.animateTo(
                          target,
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
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: Color(0xFF47CF5B),
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Obx(() {
                              final firstDay = ctrl.firstDayDate.value;
                              final today = DateTime.now();
                              final currentDay = firstDay != null
                                  ? today.difference(firstDay).inDays + 1
                                  : ctrl.streakCount.value;
                              return Text(
                                'Day $currentDay',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              );
                            }),
                          ],
                        ),
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
  final Map<String, bool> dayCompletionStatus;
  final DateTime? firstDayDate;

  _WavyPathPainter({
    this.days = 20,
    this.currentDay = 1,
    this.houses = const <String>[],
    this.selectedHouseIndex = -1,
    this.dayCompletionStatus = const <String, bool>{},
    this.firstDayDate,
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

    // Helper: compute x position for a given y using a sine-based segment shape
    double xForY(double y) {
      final yFromBottom = (size.height - y).clamp(0.0, size.height);
      final seg = (yFromBottom / segmentH).floor();
      final local = ((yFromBottom - seg * segmentH) / segmentH).clamp(0.0, 1.0);
      final angle = local * math.pi;
      final amp = w * 0.32;
      final center = w * 0.5;
      final val = math.sin(angle);
      return (seg % 2 == 0) ? center + amp * val : center - amp * val;
    }

    // Sample the continuous curve - extend beyond visible area
    // to cover all days in the entire scrollable content
    final samples = <Offset>[];
    final step = 8.0;
    // Sample from size.height (bottom) up to negative values to cover all content
    final minY = -50.0; // Start a bit beyond to ensure coverage
    for (double y = size.height; y >= minY; y -= step) {
      samples.add(Offset(xForY(y), y));
      if (samples.length > 10000) break; // Safety limit
    }

    if (samples.isNotEmpty) {
      final path = Path()..moveTo(samples[0].dx, samples[0].dy);

      for (int i = 0; i < samples.length - 1; i++) {
        final p0 = i - 1 >= 0 ? samples[i - 1] : samples[i];
        final p1 = samples[i];
        final p2 = samples[i + 1];
        final p3 = i + 2 < samples.length ? samples[i + 2] : samples[i + 1];

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

    // Precompute node centers
    final nodeCenters = <Offset>[];
    for (int i = 0; i < days; i++) {
      final cy = size.height - (i * segmentH + 150.0);
      final cx = xForY(cy);
      nodeCenters.add(Offset(cx, cy));
    }

    // Draw houses
    void drawHouse(
      Canvas canvas,
      double cx,
      double cy,
      double scale,
      String name,
      bool selected,
    ) {
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

      final roof = Path()
        ..moveTo(cx - houseW / 2 - 2, cy - houseH / 2)
        ..lineTo(cx + houseW / 2 + 2, cy - houseH / 2)
        ..lineTo(cx, cy - houseH / 2 - (10.0 * scale))
        ..close();
      canvas.drawPath(roof, roofPaint);

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

    // Place houses
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

          var bad = false;
          for (final n in nodeCenters) {
            if ((n - pos).distance < nodeAvoid) {
              bad = true;
              break;
            }
          }
          if (bad) continue;

          for (final hpos in placed) {
            if ((hpos - pos).distance < minSpacing) {
              bad = true;
              break;
            }
          }
          if (bad) continue;

          final scale = 0.9 + rand.nextDouble() * 0.6;
          final name = houses[t];
          final selected = t == selectedHouseIndex;
          drawHouse(canvas, cx, cy, scale, name, selected);
          placed.add(pos);
          placedOne = true;
        }
      }
    }

    // Draw trees
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

    // Draw day nodes from bottom upwards: Day 1 at the bottom
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < nodeCenters.length; i++) {
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

      // Calculate date for this day
      DateTime dayDate;
      if (firstDayDate != null) {
        dayDate = firstDayDate!.add(Duration(days: i));
      } else {
        dayDate = today.subtract(Duration(days: days - 1 - i));
      }

      final dayDateStr =
          '${dayDate.year.toString().padLeft(4, '0')}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

      final dayOnly = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final isToday = dayOnly == todayOnly;
      final isFuture = dayOnly.isAfter(todayOnly);
      final isPast = dayOnly.isBefore(todayOnly);
      final isComplete = dayCompletionStatus[dayDateStr] ?? false;

      // Debug logging untuk day 1 dan day 95-105 untuk troubleshooting
      if (i == 0 || (i >= 94 && i <= 104)) {
        debugPrint(
          '[StreakView] Day ${i + 1}: date=$dayDateStr, isPast=$isPast, isToday=$isToday, isFuture=$isFuture, isComplete=$isComplete',
        );
      }

      // 🔹 Aturan Tampilan Day
      // Day 1 selalu menampilkan "Day 1" text, tidak peduli isPast atau isComplete
      if (i == 0) {
        // Day 1: Always show "Day 1" text
        final dayText = TextPainter(
          text: const TextSpan(
            text: 'Day 1',
            style: TextStyle(
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
      } else if (isPast) {
        // Other past days
        if (isComplete) {
          // Progres = 100% → tampil ikon piala 🏆
          const trophy = Icons.emoji_events;
          final trophySpan = TextSpan(
            text: String.fromCharCode(trophy.codePoint),
            style: TextStyle(
              fontSize: 24,
              fontFamily: trophy.fontFamily,
              color: Colors.white,
            ),
          );
          final trophyPainter = TextPainter(
            text: trophySpan,
            textDirection: TextDirection.ltr,
          )..layout();
          trophyPainter.paint(canvas, Offset(cx - 12, cy - 12));
        } else {
          // Progres < 100% → tampil Icon X (red circle with red X)
          final redCirclePaint = Paint()
            ..color = const Color(0xFFEF5350)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(cx, cy), 24, redCirclePaint);

          final xPaint = Paint()
            ..color = Colors.white
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round;

          const offset = 10.0;
          canvas.drawLine(
            Offset(cx - offset, cy - offset),
            Offset(cx + offset, cy + offset),
            xPaint,
          );
          canvas.drawLine(
            Offset(cx + offset, cy - offset),
            Offset(cx - offset, cy + offset),
            xPaint,
          );
        }
      } else {
        // Today, tomorrow, and future days (i > 0) - tampil "Day X"
        final displayDayNumber = i + 1;
        final dayText = TextPainter(
          text: TextSpan(
            text: 'Day $displayDayNumber',
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
    }

    // Highlight the current day (today) with larger circle
    if (days > 0 && currentDay >= 1 && currentDay <= days) {
      final idx = (currentDay - 1);
      final cy = size.height - (idx * segmentH + 150.0);
      final cx = xForY(cy);

      debugPrint(
        '[StreakView] Drawing highlight for currentDay=$currentDay at position ($cx, $cy)',
      );

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

      // Current day text - show "Day X" clearly on top
      final dayText = TextPainter(
        text: TextSpan(
          text: 'Day $currentDay',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      dayText.paint(
        canvas,
        Offset(cx - dayText.width / 2, cy - dayText.height / 2),
      );
    }

    // Draw trees
    final maxTreesTop = 48;
    final randTop = math.Random(2345);
    if (samples.isNotEmpty) {
      final drawnPositions = <Offset>[];
      const nodeAvoidDist = 80.0;
      const minTreeSpacing = 70.0;

      final targetTrees = math.min(maxTreesTop, 8);
      if (samples.length >= 2 && targetTrees > 0) {
        for (int t = 0; t < targetTrees; t++) {
          final idxDouble = (t * (samples.length - 1) / (targetTrees - 1));
          int baseIdx = idxDouble.round().clamp(0, samples.length - 1);

          bool placed = false;
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
      old.days != days ||
      old.currentDay != currentDay ||
      old.dayCompletionStatus != dayCompletionStatus;
}
