import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/notification_service.dart';
import '../data/services/reminder_service.dart';
import '../data/services/auth_persistence_service.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({Key? key}) : super(key: key);

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  late NotificationService _notificationService;
  late ReminderService _reminderService;
  List<PendingNotificationRequest> _pendingNotifications = [];
  String _fcmToken = 'Loading...';
  int _minutesOffset = 1; // Default: schedule in 1 minute
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notificationService = Get.find<NotificationService>();
    _reminderService = ReminderService();
    _loadFCMToken();
    _loadPendingNotifications();
  }

  Future<void> _loadFCMToken() async {
    final token = await _notificationService.getFCMToken();
    setState(() {
      _fcmToken = token ?? 'Tidak ada token';
    });
  }

  Future<void> _loadPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    setState(() {
      _pendingNotifications = pending;
    });
  }

  Future<void> _scheduleTestReminder() async {
    final now = DateTime.now();
    final scheduledTime = now.add(Duration(minutes: _minutesOffset));

    await _notificationService.scheduleTaskReminder(
      taskId: DateTime.now().millisecondsSinceEpoch.hashCode.abs() % 100000,
      taskTitle: 'Test Task',
      taskDescription: 'Ini adalah notifikasi pengingat test yang dijadwalkan',
      scheduledDateTime: scheduledTime,
      reminderMinutesBefore: 0, // Show immediately at scheduled time
    );

    debugPrint('[TEST] Scheduled reminder for ${scheduledTime.toString()}');
    await _loadPendingNotifications();

    Get.snackbar(
      'Pengingat Dijadwalkan',
      'Notifikasi akan muncul dalam ${_minutesOffset} menit',
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _scheduleTestReminderWithBuffer() async {
    final now = DateTime.now();
    final taskTime = now.add(Duration(minutes: 5)); // Task 5 min from now
    final reminderTime = taskTime.subtract(
      Duration(minutes: 2),
    ); // Remind 2 min before

    await _notificationService.scheduleTaskReminder(
      taskId: DateTime.now().millisecondsSinceEpoch.hashCode.abs() % 100000,
      taskTitle: 'Pertemuan Penting',
      taskDescription: 'Jangan lupa hadir di pertemuan',
      scheduledDateTime: taskTime,
      reminderMinutesBefore: 2,
    );

    debugPrint(
      '[TEST] Scheduled reminder: task at $taskTime, reminder at $reminderTime',
    );
    await _loadPendingNotifications();

    Get.snackbar(
      'Pengingat Dijadwalkan',
      'Task dalam 5 menit, reminder dalam 3 menit',
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _showTestNotification() async {
    await _notificationService.showTestNotification();
    Get.snackbar(
      'Test Notification',
      'Notifikasi test ditampilkan',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _cancelAllReminders() async {
    await _notificationService.cancelAllReminders();
    await _loadPendingNotifications();
    Get.snackbar(
      'Semua Pengingat Dibatalkan',
      'Semua notifikasi yang dijadwalkan telah dihapus',
      duration: const Duration(seconds: 2),
    );
  }

  /// Test Firebase Reminder (5 menit sebelum jadwal)
  Future<void> _testFirebaseReminder() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User tidak login');
        return;
      }

      if (_fcmToken == 'Loading...' || _fcmToken == 'Tidak ada token') {
        Get.snackbar('Error', 'FCM Token tidak tersedia');
        return;
      }

      final scheduledTime = DateTime.now().add(const Duration(minutes: 3));

      final success = await _reminderService.scheduleFirebaseReminder(
        userId: user.id,
        deviceToken: _fcmToken,
        title: 'Test Firebase Reminder',
        body: 'Notifikasi ini dikirim dari Firebase Cloud Messaging',
        scheduledDateTime: scheduledTime,
        minutesBefore: 1, // Pengingat 1 menit sebelum (2 menit dari sekarang)
      );

      if (success) {
        Get.snackbar(
          'Firebase Reminder Dijadwalkan',
          'Pengingat akan dikirim dalam ~2 menit via FCM',
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar('Error', 'Gagal menjadwalkan Firebase reminder');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
      debugPrint('[TEST] Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Manual dispatch untuk test (panggil endpoint /dispatch)
  Future<void> _manualDispatch() async {
    setState(() => _isLoading = true);

    try {
      final success = await _reminderService.dispatchPendingReminders();

      if (success) {
        Get.snackbar(
          'Dispatch Berhasil',
          'Notifikasi yang jatuh tempo telah dikirim',
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar('Error', 'Gagal dispatch reminders');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Test instant FCM - buat reminder yang sudah lewat + auto dispatch
  Future<void> _testInstantFCM() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User tidak login');
        return;
      }

      if (_fcmToken == 'Loading...' || _fcmToken == 'Tidak ada token') {
        Get.snackbar('Error', 'FCM Token tidak tersedia');
        return;
      }

      // Buat reminder dengan waktu 2 menit yang LALU (sudah jatuh tempo)
      final pastTime = DateTime.now().subtract(const Duration(minutes: 2));

      final success = await _reminderService.scheduleFirebaseReminder(
        userId: user.id,
        deviceToken: _fcmToken,
        title: 'Test Instant FCM',
        body: 'Notifikasi ini langsung dikirim via Firebase',
        scheduledDateTime: pastTime,
        minutesBefore: 0, // Tidak ada buffer, langsung sekarang
      );

      if (!success) {
        Get.snackbar('Error', 'Gagal membuat reminder');
        return;
      }

      // Auto dispatch setelah reminder dibuat
      await Future.delayed(const Duration(seconds: 1));
      final dispatched = await _reminderService.dispatchPendingReminders();

      if (dispatched) {
        Get.snackbar(
          '✓ FCM Terkirim!',
          'Cek notifikasi push di device Anda',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Warning', 'Reminder dibuat tapi dispatch gagal');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifikasi & FCM'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _fcmToken,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadFCMToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload Token'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification Testing Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showTestNotification,
                        icon: const Icon(Icons.notifications),
                        label: const Text('Tampilkan Test Notifikasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Task Reminder Scheduling Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwalkan Pengingat Tugas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Pengingat dalam:'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _minutesOffset.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$_minutesOffset menit',
                            onChanged: (value) {
                              setState(() {
                                _minutesOffset = value.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _scheduleTestReminder,
                        icon: const Icon(Icons.schedule),
                        label: Text('Jadwalkan dalam $_minutesOffset menit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _scheduleTestReminderWithBuffer,
                        icon: const Icon(Icons.timer),
                        label: const Text(
                          'Test: 5 menit dengan 2 menit buffer',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pending Notifications Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pengingat yang Dijadwalkan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loadPendingNotifications,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_pendingNotifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Tidak ada pengingat yang dijadwalkan',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _pendingNotifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${notification.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('Title: ${notification.title ?? '-'}'),
                                  Text('Body: ${notification.body ?? '-'}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    if (_pendingNotifications.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cancelAllReminders,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Batalkan Semua'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Firebase Testing Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Firebase Push Notification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jadwalkan notifikasi via Firebase Cloud Messaging (FCM).\n'
                      'Membutuhkan backend yang sudah di-setup.\n'
                      'Lihat FIREBASE_SETUP.md untuk setup lengkap.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testFirebaseReminder,
                        icon: const Icon(Icons.cloud_upload),
                        label: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Schedule Firebase Reminder (3 menit)',
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testInstantFCM,
                        icon: const Icon(Icons.flash_on),
                        label: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('🚀 Test Instant FCM (Langsung)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _manualDispatch,
                        icon: const Icon(Icons.send),
                        label: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Manual Dispatch Pending'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cara Testing:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '=== LOCAL NOTIFICATIONS ===\n'
                      '1. Jadwalkan pengingat menggunakan slider\n'
                      '2. Tunggu sampai waktu yang dijadwalkan\n'
                      '3. Notifikasi akan muncul otomatis\n'
                      '4. Lihat pending notifications untuk melihat daftar\n'
                      '\n'
                      '=== FIREBASE NOTIFICATIONS ===\n'
                      '1. Setup: Ikuti FIREBASE_SETUP.md\n'
                      '2. Klik "Schedule Firebase Reminder"\n'
                      '3. Tunggu ~2 menit atau klik "Manual Dispatch"\n'
                      '4. Notifikasi FCM dari server akan muncul\n'
                      '5. Lihat console logs [FCM] dan [ReminderService]',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
