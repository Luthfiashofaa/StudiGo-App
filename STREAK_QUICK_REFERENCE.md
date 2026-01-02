# 🔥 Streak Database - Quick Reference

## Installation (3 Steps)

### 1️⃣ Run Migration
```
Supabase Dashboard
  → SQL Editor
  → New Query
  → Paste: supabase/migrations/20260102_create_streak_tables.sql
  → Run
```

### 2️⃣ Verify Tables
```
Supabase Dashboard
  → Table Editor
  → Check: user_streaks ✓
  → Check: daily_progress ✓
```

### 3️⃣ Done! ✅
```
Auto-sync already working!
```

---

## Usage

### Update Progress (Auto-syncs 🔄)
```dart
await StreakHelper.setProgress(100.0);
```

### Get Streak
```dart
int streak = StreakHelper.getStreakCount();
```

### Load from Database
```dart
final streak = await StreakDatabase.loadCurrentStreak(userId);
```

### Load History
```dart
final last30 = await StreakDatabase.loadProgressHistory(userId, days: 30);
```

---

## Data Locations

| Data | Location | Purpose |
|------|----------|---------|
| current_streak | Local + Database | Today's count |
| longest_streak | Database only | Personal record |
| progress (0-100) | Local + Database | Daily tracking |
| history | Local (cache) | Quick access |

---

## Query Database

### Current streak
```sql
SELECT current_streak FROM user_streaks WHERE user_id = 'xxx';
```

### Progress today
```sql
SELECT progress_percentage FROM daily_progress 
WHERE user_id = 'xxx' AND date = CURRENT_DATE;
```

### Progress history
```sql
SELECT date, progress_percentage FROM daily_progress
WHERE user_id = 'xxx' ORDER BY date DESC LIMIT 30;
```

### Longest streak
```sql
SELECT longest_streak FROM user_streaks WHERE user_id = 'xxx';
```

---

## Auto-Sync Behavior

| Event | Local | Database | Time |
|-------|-------|----------|------|
| Progress update | ✅ Save | ✅ Sync | Instant |
| Streak increase | ✅ Save | ✅ Sync | Instant |
| App open | ✅ Load | ✅ Sync | On init |
| No internet | ✅ Save | ⏳ Queue | Auto-retry |

---

## Troubleshooting

| Issue | Check | Fix |
|-------|-------|-----|
| Data not syncing | Internet on? | Check connection |
| Table not found | Ran migration? | Run SQL again |
| RLS error | User logged in? | Ensure auth first |
| Offline data lost | Not possible | Check local storage |

---

## SQL Queries for Analytics

### Top streaks
```sql
SELECT user_id, current_streak FROM user_streaks 
ORDER BY current_streak DESC LIMIT 10;
```

### Completion rate today
```sql
SELECT 
  COUNT(CASE WHEN progress_percentage >= 100 THEN 1 END) as completed,
  COUNT(*) as total
FROM daily_progress WHERE date = CURRENT_DATE;
```

### Average daily progress
```sql
SELECT AVG(progress_percentage) as avg 
FROM daily_progress WHERE date = CURRENT_DATE;
```

---

## Files

- **Setup**: `SETUP_STREAK_DATABASE.md`
- **Guide**: `docs/STREAK_DATABASE_INTEGRATION.md`  
- **Checklist**: `IMPLEMENTATION_CHECKLIST.md`
- **Summary**: `STREAK_DATABASE_SUMMARY.md`
- **Code**: `streak_controller.dart`, `streak_database.dart`

---

## Offline Mode ✅

Works perfectly offline:
1. Update progress → saved locally
2. No internet → sync skipped
3. Internet back → auto-sync
4. **No data loss** ✓

---

## Status: 🟢 READY

Code complete. Database ready. Just run migration!

