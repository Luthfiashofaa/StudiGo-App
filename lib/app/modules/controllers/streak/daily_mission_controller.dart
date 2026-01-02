import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mission_models.dart';
import 'streak_controller.dart';

class DailyMissionController extends GetxController {
  final RxList<Mission> missions = <Mission>[].obs;
  final RxBool isLoading = true.obs;
  final RxString todayIso = ''.obs;

  SharedPreferences? _prefs;
  late final StreakController _streak;

  static const _kMissionsData = 'missions_today_data';
  static const _kMissionsDate = 'missions_today_date';

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<StreakController>()) {
      Get.lazyPut<StreakController>(() => StreakController());
    }
    _streak = Get.find<StreakController>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _streak.restoreFromStorage();

    final today = DateTime.now();
    final todayKey = _dateKey(today);
    todayIso.value = todayKey;

    await _streak.reconcileForToday(todayKey);
    await _loadOrGenerateMissions(todayKey, today);
    isLoading.value = false;
  }

  Future<void> refreshMissions() async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    await _loadOrGenerateMissions(todayKey, today, forceGenerate: true);
  }

  Future<void> _loadOrGenerateMissions(
    String todayKey,
    DateTime today, {
    bool forceGenerate = false,
  }) async {
    final storedDate = _prefs?.getString(_kMissionsDate);
    if (!forceGenerate && storedDate == todayKey) {
      final raw = _prefs?.getString(_kMissionsData);
      if (raw != null) {
        final decoded = (jsonDecode(raw) as List<dynamic>)
            .map((e) => Mission.fromJson(e as Map<String, dynamic>))
            .toList();
        missions.assignAll(decoded);
        await _checkCompletion();
        return;
      }
    }

    final generated = _generateMissions(today);
    missions.assignAll(generated);
    await _persistMissions(todayKey);
    await _checkCompletion();
  }

  List<Mission> _generateMissions(DateTime today) {
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final rand = Random(seed);

    final templates = <Map<String, dynamic>>[
      {'title': 'Focus 25 minutes', 'icon': 'track_changes', 'base': 20},
      {'title': 'Finish Assignment', 'icon': 'assignment_turned_in', 'base': 8},
      {'title': 'Streak 2 Days', 'icon': 'whatshot', 'base': 6},
      {'title': 'Rest 10 minutes', 'icon': 'event_seat', 'base': 6},
      {'title': 'Read 10 pages', 'icon': 'track_changes', 'base': 10},
      {'title': 'Quick review', 'icon': 'assignment_turned_in', 'base': 4},
    ];

    templates.shuffle(rand);
    final selected = templates.take(4).toList();

    return List.generate(selected.length, (index) {
      final t = selected[index];
      final total = (t['base'] as int) + rand.nextInt(5);
      return Mission(
        id: '${seed}_$index',
        title: t['title'] as String,
        progress: 0,
        total: total,
        iconKey: t['icon'] as String,
      );
    });
  }

  Future<void> markMissionComplete(String missionId) async {
    final idx = missions.indexWhere((m) => m.id == missionId);
    if (idx == -1) return;
    final mission = missions[idx];
    if (mission.isComplete) return;

    missions[idx] = mission.copyWith(progress: mission.total);
    await _persistMissions(todayIso.value);
    await _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    final done = missions.isNotEmpty && missions.every((m) => m.isComplete);
    if (done && todayIso.value.isNotEmpty) {
      // Update progress to 100% when all missions complete
      final oldStreak = _streak.streakCount.value;
      await _streak.updateTodayProgress(100.0);

      // Show success message if streak increased
      if (_streak.streakCount.value > oldStreak) {
        Get.snackbar(
          '🔥 Streak Updated!',
          'Congratulations! Your streak is now ${_streak.streakCount.value} days!',
          backgroundColor: const Color(0xFF47CF5B),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        );
      }
    } else {
      // Calculate partial progress based on completed missions
      final totalMissions = missions.length;
      if (totalMissions > 0) {
        final completedCount = missions.where((m) => m.isComplete).length;
        final progress = (completedCount / totalMissions) * 100.0;
        await _streak.updateTodayProgress(progress);
      }
    }
  }

  Future<void> _persistMissions(String todayKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_kMissionsDate, todayKey);
    await _prefs?.setString(
      _kMissionsData,
      jsonEncode(missions.map((e) => e.toJson()).toList()),
    );
  }

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
