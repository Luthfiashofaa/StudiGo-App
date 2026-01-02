# 🔥 Sistem Streak Sederhana

## Cara Kerja

Sistem sekarang lebih sederhana:
- Setiap hari punya **progress 0-100%**
- Ketika progress mencapai **100%** → streak bertambah
- Jika hari sebelumnya sudah 100%, hari ini otomatis lanjut streak

## Logika Streak

```
Hari 1: Progress 100% ✓ → Streak = 1
Hari 2: Progress 100% ✓ → Streak = 2 (lanjut dari hari sebelumnya)
Hari 3: Progress 50%  ✗ → Streak tetap 2 (belum 100%)
Hari 4: Progress 100% ✓ → Streak = 1 (reset karena hari 3 skip)
```

## Cara Update Progress

### 1. Dari Controller (Daily Mission)
```dart
// Sudah otomatis terintegrasi di DailyMissionController
// Progress dihitung dari missions yang complete:
// - 1 dari 4 mission → 25% progress
// - 4 dari 4 mission → 100% progress → STREAK +1 ✨
```

### 2. Dari Mana Saja (Manual)
```dart
import 'package:studigo/app/modules/controllers/streak/streak_helper.dart';

// Tambah progress
await StreakHelper.addProgress(25.0);  // +25%
await StreakHelper.addProgress(50.0);  // +50%

// Set langsung ke 100%
await StreakHelper.setProgress(100.0);  // Streak akan bertambah!

// Cek progress hari ini
double progress = StreakHelper.getTodayProgress();
print('Progress: $progress%');

// Cek apakah hari ini sudah complete
bool isDone = StreakHelper.isCompletedToday();

// Get streak count
int streak = StreakHelper.getStreakCount();
```

### 3. Contoh: Tambah Progress dari Study Timer
```dart
// Di file timer_controller.dart
import 'package:studigo/app/modules/controllers/streak/streak_helper.dart';

void onStudySessionComplete() {
  // Setiap sesi belajar 25 menit = +10% progress
  StreakHelper.addProgress(10.0);
  
  // Jika sudah 10 sesi (10x10% = 100%), streak otomatis bertambah!
}
```

### 4. Contoh: Progress dari Task Completion
```dart
// Di file task_controller.dart
import 'package:studigo/app/modules/controllers/streak/streak_helper.dart';

void onTaskComplete(int totalTasks, int completedTasks) {
  // Progress berdasarkan jumlah task selesai
  double progress = (completedTasks / totalTasks) * 100.0;
  StreakHelper.setProgress(progress);
}
```

## File Penting

- **streak_controller.dart**: Controller utama untuk streak dan progress
- **streak_helper.dart**: Helper untuk update progress dari mana saja
- **daily_mission_controller.dart**: Contoh implementasi dengan missions
- **streak_view.dart**: UI untuk menampilkan streak

## Auto-Reset

- Setiap hari baru, progress otomatis reset ke 0%
- Kalau kemarin belum 100%, streak akan reset
- Data disimpan di SharedPreferences, aman meskipun app ditutup

## Testing

```dart
// Test manual:
1. Panggil StreakHelper.setProgress(50.0) → progress 50%
2. Panggil StreakHelper.setProgress(100.0) → STREAK +1! 🔥
3. Restart app → streak dan progress tetap tersimpan
4. Besok buka app → progress reset ke 0%, siap mulai lagi
```
