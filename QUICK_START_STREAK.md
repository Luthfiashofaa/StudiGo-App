# 🚀 Quick Start - Sistem Streak

## TL;DR
Progress 0-100% setiap hari. Kalau 100% = streak +1. Mudah!

## Import
```dart
import 'package:studigo/app/modules/controllers/streak/streak_helper.dart';
```

## Update Progress (Pilih salah satu)

### Option 1: Tambah Progress
```dart
await StreakHelper.addProgress(25.0);  // +25%
```

### Option 2: Set Langsung
```dart
await StreakHelper.setProgress(100.0); // Set ke 100%
```

## Get Data
```dart
// Progress hari ini
double progress = StreakHelper.getTodayProgress();

// Cek sudah complete?
bool done = StreakHelper.isCompletedToday();

// Streak count
int streak = StreakHelper.getStreakCount();
```

## Widget Progress Bar
```dart
import 'package:studigo/app/modules/views/streak/daily_progress_card.dart';

// Di mana aja dalam body:
DailyProgressCard()
```

## Contoh Real World

### Study Timer
```dart
void onTimerComplete() {
  StreakHelper.addProgress(10.0); // +10% per sesi
}
```

### Task List
```dart
void onTaskDone(int completed, int total) {
  double progress = (completed / total) * 100.0;
  StreakHelper.setProgress(progress);
}
```

### Manual Button
```dart
ElevatedButton(
  onPressed: () => StreakHelper.setProgress(100.0),
  child: Text('Complete Today'),
)
```

## Logika Otomatis
- ✅ Auto-reset ke 0% setiap hari baru
- ✅ Auto-save ke storage
- ✅ Streak +1 saat progress 100%
- ✅ Streak reset jika skip 1 hari

## That's it! 🎉
Tinggal panggil `StreakHelper.addProgress()` atau `setProgress()` dari mana aja!
