# Sistem Notifikasi Pengingat Tugas

## Cara Kerja

Sistem notifikasi StudiGo menggunakan `flutter_local_notifications` untuk mengirimkan pengingat terjadwal kepada pengguna tentang tugas yang akan datang.

### Alur Notifikasi

```
User membuat/update Schedule
        ↓
AddScheduleController.createSchedule() / updateSchedule()
        ↓
_scheduleNotificationIfEnabled()
        ↓
Fetch user's notification settings dari database
        ↓
if (enableNotifications == true)
        ↓
NotificationService.scheduleTaskReminder()
        ↓
Scheduled notification akan dikirim X menit sebelum task dimulai
```

### Fitur Utama

1. **Notifikasi Otomatis**
   - Notifikasi dijadwalkan secara otomatis saat pengguna membuat/update tugas
   - Waktu pengingat dapat dikontrol melalui settings di profile (5, 10, 15, 30, atau 60 menit)

2. **Toggle Enable/Disable**
   - User dapat mengaktifkan/menonaktifkan notifikasi dari Profile Settings
   - Ketika dinonaktifkan, semua notifikasi yang dijadwalkan akan dibatalkan
   - Ketika diaktifkan kembali, semua notifikasi akan dijadwalkan ulang

3. **Smart Rescheduling**
   - Ketika user mengubah reminder time setting, semua notifikasi akan dijadwalkan ulang dengan waktu baru
   - Notifikasi lama otomatis dibatalkan sebelum dijadwalkan ulang

4. **Pembatalan Otomatis**
   - Ketika user menghapus tugas, notifikasi terkait akan otomatis dibatalkan

## File-File Komponen

### 1. **NotificationService** (`lib/app/data/services/notification_service.dart`)
   - Singleton service yang menangani semua operasi notifikasi
   - Methods utama:
     - `initialize()` - Inisialisasi flutter_local_notifications
     - `requestPermissions()` - Minta izin notifikasi dari user
     - `scheduleTaskReminder()` - Jadwalkan notifikasi untuk task
     - `cancelTaskReminder()` - Batalkan notifikasi untuk task
     - `cancelAllReminders()` - Batalkan semua notifikasi

### 2. **Main.dart** (Entry point)
   - Inisialisasi `NotificationService` di early startup
   - Memastikan sistem notifikasi siap sebelum app berjalan

### 3. **AddScheduleController** (`lib/app/modules/controllers/schedule/add_schedule_controller.dart`)
   - Method `_scheduleNotificationIfEnabled()` - Cek settings dan jadwalkan notifikasi
   - Dipanggil setelah `createSchedule()` dan `updateSchedule()` berhasil

### 4. **ScheduleController** (`lib/app/modules/controllers/schedule/schedule_controller.dart`)
   - Method `deleteSchedule()` - Batalkan notifikasi saat task dihapus

### 5. **ProfileController** (`lib/app/modules/controllers/profile/profile_controller.dart`)
   - Method `setEnableNotifications()` - Toggle notifikasi on/off
   - Method `setReminderMinutesBefore()` - Ubah waktu reminder
   - Method `_rescheduleAllNotifications()` - Jadwalkan ulang semua notifikasi

### 6. **AppShell** (`lib/app/modules/views/shell/app_shell.dart`)
   - Method `_requestNotificationPermission()` - Minta izin saat app dibuka pertama kali

## Cara Menggunakan

### Untuk User

1. **Buat Task Baru**
   - Tugas akan otomatis mendapat notifikasi pengingat sesuai setting yang dipilih di Profile

2. **Ubah Waktu Pengingat**
   - Buka Profile > Notification Reminder Settings
   - Toggle switch untuk enable/disable
   - Pilih waktu pengingat (5, 10, 15, 30, atau 60 menit)
   - Settings akan otomatis tersimpan dan semua notifikasi akan dijadwalkan ulang

3. **Terima Notifikasi**
   - Notifikasi akan muncul di status bar Android/iOS pada waktu yang dijadwalkan
   - User bisa klik untuk membuka app dan melihat detail task

### Untuk Developer

#### Initialize di Startup
```dart
// main.dart - sudah dilakukan
final notificationService = NotificationService();
await notificationService.initialize();
```

#### Schedule Notifikasi untuk Task
```dart
// Dipanggil otomatis di AddScheduleController
await _notificationService.scheduleTaskReminder(
  taskId: numericId,
  taskTitle: 'Belajar Matematika',
  taskDescription: 'BAB 5: Integral',
  scheduledDateTime: DateTime(2025, 12, 17, 10, 0),
  reminderMinutesBefore: 15,
);
```

#### Batalkan Notifikasi
```dart
// Dipanggil otomatis saat delete atau disable notifications
await _notificationService.cancelTaskReminder(taskId);
await _notificationService.cancelAllReminders();
```

## Konfigurasi Platform Spesifik

### Android

File: `android/app/build.gradle`
- Tidak perlu konfigurasi tambahan (sudah support API 33+)

File: `android/app/src/main/AndroidManifest.xml`
- Pastikan permission sudah ada (akan diminta saat runtime untuk API 33+):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS

File: `ios/Runner/Info.plist`
- Tidak perlu konfigurasi khusus (permission diminta saat runtime)

## Troubleshooting

### Notifikasi Tidak Muncul

1. **Cek Permission**
   - Android 13+: Pastikan user grant POST_NOTIFICATIONS permission
   - iOS: Pastikan user grant notification permission saat diminta

2. **Cek Setting User**
   - Buka Profile → Notification Reminder Settings
   - Pastikan toggle "Enable Notifications" aktif

3. **Cek Debug Logs**
   - Cari pattern `[AddScheduleController]` atau `[NotificationService]` di logs
   - Pastikan tidak ada error saat scheduling

4. **Test Notification**
   - Buka Developer Tools → Run test notification
   - Pastikan test notification muncul (jika ada)

### Notifikasi Ganda/Duplikat

- Ini bisa terjadi jika task di-update multiple times
- System akan otomatis handle dengan cancel notifikasi lama sebelum schedule baru

## Database Schema

Pastikan tabel `users` memiliki columns:
```sql
ALTER TABLE users ADD COLUMN enable_notifications BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN reminder_minutes_before INTEGER DEFAULT 15;
```

## Future Enhancements

- [ ] Custom notification sound
- [ ] Notification history/logs
- [ ] Different reminders for different categories
- [ ] Recurring task reminders
- [ ] Integration dengan calendar app
- [ ] Rich notification dengan action buttons (Complete, Snooze, Dismiss)
