# 📊 Logika Streak & Daily Progress

## Gambaran Umum

Sistem streak StudiGo terdiri dari 3 komponen utama:

### 1. **Database `schedules`** 
Menyimpan data jadwal/task individual yang dibuat user:
```
- title (nama task)
- description (deskripsi)
- date (tanggal task)
- start_time, end_time (waktu)
- repeat_daily (apakah setiap hari)
- priority, category
```

### 2. **Database `daily_progress`** 
Menyimpan agregat progress HARIAN (berapa % hari ini):
```
- user_id + date (unique key)
- completed_tasks (jumlah task yang complete)
- is_completed (boolean: apakah sudah 100%)
```

### 3. **Database `user_streaks`**
Menyimpan data streak user:
```
- user_id (unique)
- current_streak (berapa hari consecutive)
- longest_streak (rekor terbaik)
- last_completed_date (kapan complete terakhir)
```

---

## 🔄 Flow Lengkap

### **A. User Centang/Unchecklist Task**

```
User klik checkbox di schedule
  ↓
HomeController.toggleTaskCompletion()
  ↓
Hitung: completedTasks / totalTasks hari ini
  ↓
StreakHelper.setProgress(percentage, completedTaskCount)
  ↓
StreakController.updateTodayProgress()
  ↓
if (progress >= 100%) {
  _incrementStreak() // streak ++
}
  ↓
_persist() → _syncToDatabase()
  ↓
INSERT/UPDATE daily_progress:
  - completed_tasks: 3
  - is_completed: true/false
  
UPDATE user_streaks:
  - current_streak: N
  - last_completed_date: 2026-01-03
```

---

### **B. Pergantian Hari (NEW DAY LOGIC) ✨**

**Dipanggil dari:** `HomeController._loadTodayTasks()` saat app dibuka/resume

```
App detect hari baru (todayProgressDate != today)
  ↓
Panggil: StreakController.reconcileForToday(todayIso)
  ↓
Query database: KEMARIN 100% atau tidak?
  SELECT is_completed FROM daily_progress
  WHERE user_id = xxx AND date = '2026-01-02'
  
IF kemarin = 100% (is_completed = true):
  ✅ Streak += 1 (CONSECUTIVE)
  ✅ Update lastCompletedDate = kemarin
  
ELSE (kemarin < 100%):
  ❌ Streak = 0 (BROKEN)
  ❌ Clear history
  ❌ Update lastCompletedDate = ''
  ↓
Reset today's progress:
  - todayProgress = 0%
  - todayProgressDate = today
  - completed_tasks = 0
  ↓
_persist() → _syncToDatabase()
```

---

## 📈 Contoh Skenario

### Skenario 1: Consecutive Days (Streak Bertambah)

```
Hari 1 (Jan 1):
  - Complete 3 dari 3 tasks → is_completed = true
  - Streak: 0 → 1 ✅
  - Save: daily_progress.is_completed = true

Hari 2 (Jan 2):
  - App dibuka → reconcileForToday('2026-01-02')
  - Check kemarin: is_completed = true ✅
  - Streak: 1 → 2 ✅
  - Reset daily progress = 0%
  - User mulai dari 0 lagi

Hari 3 (Jan 3):
  - Complete 2 dari 3 tasks → is_completed = false
  - Tidak increment streak (belum 100%)
  - Save: daily_progress.is_completed = false

Hari 4 (Jan 4):
  - App dibuka → reconcileForToday('2026-01-04')
  - Check kemarin (Jan 3): is_completed = false ❌
  - STREAK BROKEN: 2 → 0 ❌
  - History cleared
```

### Skenario 2: Skipped Day (Streak Terputus)

```
Hari 1 (Jan 1):
  - 100% complete → Streak: 1
  
Hari 2 (Jan 2):
  - App tidak dibuka (offline/forgot)
  - daily_progress.is_completed = false (default/last saved)
  
Hari 3 (Jan 3):
  - App dibuka → reconcileForToday('2026-01-03')
  - Check kemarin (Jan 2): is_completed = false ❌
  - STREAK BROKEN: 1 → 0 ❌
```

### Skenario 3: Miss Day tapi Ada Streak

```
Hari 1 (Jan 1): 100% → Streak: 1
Hari 2 (Jan 2): Tidak centang apapun (0%) → Daily Progress = 0%
Hari 3 (Jan 3): App dibuka
  - reconcileForToday('2026-01-03')
  - Check Jan 2: is_completed = false ❌
  - STREAK BROKEN → 0
```

---

## 🔐 RLS Policies

Semua tabel dilindungi dengan Row Level Security:

```sql
-- User hanya bisa lihat data mereka sendiri
SELECT: auth.uid() = user_id
INSERT: auth.uid() = user_id
UPDATE: auth.uid() = user_id
DELETE: auth.uid() = user_id
```

---

## 📱 Offline Support

- **Local Storage**: SharedPreferences menyimpan semua data locally
- **Sync**: Automatic sync ke database saat _persist() dipanggil
- **Reconciliation**: reconcileForToday() bisa jalan offline (check local data jika database unreachable)

---

## 🐛 Debug Info

**Log Messages** di console untuk track flow:

```
[HomeController] New day detected: 2026-01-03 (was 2026-01-02)
[StreakController] Yesterday progress: 3 tasks, completed: true
[StreakController] Streak incremented to 2
[StreakController] Successfully synced to database: 3 tasks, 100.0% complete
```

---

## ✅ Checklist Implementasi

- [x] Database schema: schedules, daily_progress, user_streaks
- [x] Checkbox toggle → progress calculation
- [x] Progress sync ke daily_progress
- [x] Daily progress sync ke user_streaks
- [x] New day detection
- [x] Yesterday progress check
- [x] Streak increment logic
- [x] Streak broken logic
- [x] RLS policies
- [x] Debug logging
- [ ] Unit tests (TODO)
- [ ] E2E tests (TODO)
