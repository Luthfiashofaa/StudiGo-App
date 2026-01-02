# 🔥 Streak & Database Integration Guide

## Overview

Sekarang streak data **otomatis tersync** dengan Supabase database:

```
Local Storage (SharedPreferences)  ←→  Supabase Database
        ↓                                     ↓
    Offline OK                          Shared across devices
```

## Data Flow

```
User App
    ↓
StreakHelper.addProgress(25)
    ↓
StreakController.updateTodayProgress()
    ↓
_persist() (save local)
    ↓
_syncToDatabase() (save to Supabase)
    ↓
Data tersimpan di 2 tempat ✅
```

## Setup Checklist

- [ ] Run SQL migration: `supabase/migrations/20260102_create_streak_tables.sql`
- [ ] Verify 2 tables muncul: `user_streaks` dan `daily_progress`
- [ ] Ensure user sudah login sebelum streak track
- [ ] Enable RLS policies (sudah included di migration)

## Database Tables

### user_streaks
```
- user_id (unique)
- current_streak (berapa hari berturut-turut)
- longest_streak (rekor tertinggi pernah)
- last_completed_date (tanggal terakhir 100%)
```

### daily_progress
```
- user_id + date (unique per hari per user)
- progress_percentage (0-100)
- is_completed (auto: true jika >= 100)
```

## Auto Sync Behavior

### Saat App Start
```dart
StreakController.restoreFromStorage()
    ↓
Load dari local SharedPreferences
    ↓
Auto sync ke database
```

### Saat Update Progress
```dart
StreakHelper.setProgress(100.0)
    ↓
StreakController.updateTodayProgress()
    ↓
_persist() → _syncToDatabase()
    ↓
Local + Database updated
```

### Saat Streak Increment
```dart
Progress 100% reached
    ↓
_incrementStreak()
    ↓
_persist() → _syncToDatabase()
    ↓
Longest streak updated di database
```

## Query Database

### Load streak saat user login
```dart
import 'package:studigo/app/modules/controllers/streak/streak_database.dart';

final currentStreak = await StreakDatabase.loadCurrentStreak(userId);
```

### Load progress history
```dart
final last30Days = await StreakDatabase.loadProgressHistory(userId, days: 30);

// Display di chart/graph
for (final day in last30Days) {
  print('${day['date']}: ${day['progress_percentage']}%');
}
```

### Get user stats
```dart
final stats = await StreakDatabase.getUserStreakStats(userId);
print('Current: ${stats['current_streak']}');
print('Longest: ${stats['longest_streak']}');
```

## Offline Mode

✅ **Fully works offline:**
- Progress disimpan di local
- Auto-sync saat internet balik
- No data loss

**Flow:**
```
Offline
  ↓
Progress saved to local ✓
  ↓
No internet → sync skip (silently)
  ↓
Internet back
  ↓
_persist() trigger auto-sync
  ↓
Database updated ✓
```

## Force Sync (jika perlu)

```dart
import 'package:studigo/app/modules/controllers/streak/streak_database.dart';

final userId = _supabaseService.currentUser?.id ?? '';
await StreakDatabase.forceSync(
  userId,
  currentStreak: 5,
  lastCompletedDate: '2025-01-02',
  todayProgress: 75.0,
);
```

## Debugging

### Check local data
```dart
final progress = StreakHelper.getTodayProgress();
final streak = StreakHelper.getStreakCount();
print('Local: Streak=$streak, Progress=$progress%');
```

### Check database
```sql
SELECT * FROM user_streaks WHERE user_id = 'xxx';
SELECT * FROM daily_progress WHERE user_id = 'xxx' ORDER BY date DESC LIMIT 10;
```

### Check logs
```
[StreakController] Syncing to database for user: xxx
[StreakController] Successfully synced to database
```

## Best Practices

1. **Always check user is logged in**
   ```dart
   if (_supabaseService.currentUser != null) {
     // proceed with streak
   }
   ```

2. **Use StreakHelper untuk update progress**
   ```dart
   await StreakHelper.setProgress(100.0); // Auto sync
   ```

3. **Don't force sync too often** (can overwhelm server)
   ```dart
   // Good: Let auto-sync handle it
   await StreakHelper.addProgress(25.0);
   
   // Avoid: Manual sync every second
   ```

4. **Longest streak tracking**
   - Auto-updated saat current streak bertambah
   - Query: `SELECT longest_streak FROM user_streaks`

## Leaderboard / Analytics

```sql
-- Top 10 current streaks
SELECT user_id, current_streak 
FROM user_streaks 
ORDER BY current_streak DESC 
LIMIT 10;

-- Average progress per day
SELECT DATE(date) as day, AVG(progress_percentage) as avg_progress
FROM daily_progress
WHERE user_id = 'xxx'
GROUP BY DATE(date)
ORDER BY day DESC
LIMIT 30;

-- Completion rate hari ini
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN progress_percentage >= 100 THEN 1 END) as completed
FROM daily_progress
WHERE date = CURRENT_DATE;
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Data tidak sync | Check: user login? Internet? |
| Local/DB mismatch | Gunakan `forceSync()` |
| Tabel not found | Run migration SQL dulu |
| RLS error | Check: user ID correct? |

## Files Created

- `streak_controller.dart` - Updated dengan Supabase sync
- `streak_database.dart` - Utility untuk query database
- `streak_database_examples.dart` - Contoh penggunaan
- `supabase/migrations/20260102_create_streak_tables.sql` - Migration SQL
- `SETUP_STREAK_DATABASE.md` - Setup guide

---

**Sekarang streak data fully backed up di Supabase!** 🎉
