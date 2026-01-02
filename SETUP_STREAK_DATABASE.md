# 🔥 Setup Streak Database di Supabase

## Step 1: Jalankan Migration SQL

1. Buka Supabase Dashboard → Project Anda
2. Pilih **SQL Editor** di sidebar
3. Buat **New Query**
4. Copy-paste isi dari file `supabase/migrations/20260102_create_streak_tables.sql`
5. Click **Run**

Ini akan membuat 2 tabel:
- `user_streaks` - Menyimpan current streak, longest streak, last completed date
- `daily_progress` - Menyimpan progress 0-100% per hari

## Step 2: Verifikasi Tabel

Di Supabase Dashboard, buka **Table Editor**, pastikan ada 2 tabel baru:
- ✅ `user_streaks`
- ✅ `daily_progress`

## Struktur Tabel

### user_streaks
```
id (bigint)                    - Primary key
user_id (uuid)                 - Reference ke auth.users
current_streak (integer)       - Streak count hari ini
longest_streak (integer)       - Longest streak ever
last_completed_date (text)     - Format: YYYY-MM-DD
created_at (timestamp)
updated_at (timestamp)
```

### daily_progress
```
id (bigint)                    - Primary key
user_id (uuid)                 - Reference ke auth.users
date (date)                    - Format: YYYY-MM-DD
progress_percentage (float)    - 0-100
is_completed (boolean)         - Apakah sudah 100%
created_at (timestamp)
updated_at (timestamp)
UNIQUE(user_id, date)          - 1 record per user per hari
```

## Cara Kerja Auto-Sync

**Sekarang data streak otomatis tersimpan ke Supabase:**

1. Ketika user membuka app → `StreakController` load dari local + sync ke database
2. Setiap kali progress update → otomatis save ke local + Supabase
3. Setiap kali streak bertambah → otomatis save ke local + Supabase

**Flow:**
```
User update progress
    ↓
StreakHelper.addProgress(25.0)
    ↓
StreakController.updateTodayProgress()
    ↓
_persist() (local) + _syncToDatabase() (Supabase)
    ↓
Data tersimpan di kedua tempat ✅
```

## Query Data dari Database

### Get user's current streak
```sql
SELECT current_streak FROM user_streaks WHERE user_id = 'xxx';
```

### Get user's daily progress history
```sql
SELECT * FROM daily_progress 
WHERE user_id = 'xxx' 
ORDER BY date DESC 
LIMIT 30;
```

### Get longest streak
```sql
SELECT longest_streak FROM user_streaks WHERE user_id = 'xxx';
```

## Security (RLS)

✅ Row Level Security (RLS) sudah diaktifkan
- Users hanya bisa melihat/edit data mereka sendiri
- Data user lain tidak bisa diakses

## Troubleshooting

**Jika sync error:**
- Check: User sudah login?
- Check: User ID valid?
- Check: Internet connection?
- Data tetap tersimpan di local, tidak hilang

**Jika tabel tidak muncul:**
- Pastikan sudah run SQL migration
- Refresh browser / dashboard

## Dashboard Query (untuk monitoring)

```sql
-- Hitung user dengan streak > 5 hari
SELECT COUNT(*) as active_users 
FROM user_streaks 
WHERE current_streak > 5;

-- Top 10 longest streaks
SELECT user_id, longest_streak 
FROM user_streaks 
ORDER BY longest_streak DESC 
LIMIT 10;

-- Progress summary hari ini
SELECT 
  COUNT(*) as total_users,
  ROUND(AVG(progress_percentage), 1) as avg_progress,
  ROUND(COUNT(CASE WHEN progress_percentage >= 100 THEN 1 END) * 100.0 / COUNT(*), 1) as percent_completed
FROM daily_progress 
WHERE date = CURRENT_DATE;
```
