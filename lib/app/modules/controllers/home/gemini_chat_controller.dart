import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiChatController extends GetxController {
  final messageController = TextEditingController();
  final messages = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  // For storing schedule data to provide context
  var scheduleContext = ''.obs;

  // Get schedule data from other controllers
  late final dynamic scheduleController;
  late final dynamic streakController;
  late final dynamic supabaseService;

  // Store user's actual schedule and tasks
  var userSchedules = <Map<String, dynamic>>[].obs;
  var userTasks = <Map<String, dynamic>>[].obs;

  // Gemini AI Model
  GenerativeModel? _geminiModel;
  ChatSession? _chatSession;
  String? _workingModelName;

  // Get API Key from .env file
  String get _geminiApiKey {
    final envKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    final defineKey = const String.fromEnvironment('GEMINI_API_KEY');
    final key = envKey.isNotEmpty ? envKey : defineKey;

    if (kDebugMode) {
      final source = envKey.isNotEmpty
          ? 'dotenv'
          : defineKey.isNotEmpty
          ? 'dart-define'
          : 'none';
      final masked = key.length > 8
          ? '${key.substring(0, 4)}...${key.substring(key.length - 4)}'
          : key;
      debugPrint('[Gemini] Key source: $source (len=${key.length}, $masked)');
    }

    return key.isNotEmpty ? key : 'YOUR_GEMINI_API_KEY_HERE';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeGeminiAI();
    _initializeControllers();
    _initializeWithGreeting();
    _loadUserData();
  }

  Future<void> _initializeGeminiAI() async {
    try {
      final apiKey = _geminiApiKey;
      print('🔑 Checking Gemini API Key...');
      print(
        '   API Key status: ${apiKey == 'YOUR_GEMINI_API_KEY_HERE' ? '❌ NOT SET' : '✅ Found'}',
      );

      // Validate API key
      if (apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.isEmpty) {
        print('⚠️  GEMINI API KEY NOT SET!');
        print('   Using template responses only.');
        print('');
        print('📝 To enable real AI:');
        print('   1. Get free API key: https://aistudio.google.com/app/apikey');
        print('   2. Add to .env file: GEMINI_API_KEY=your_key_here');
        print('   3. Restart app');
        print('');
        return;
      }

      if (apiKey.length < 20) {
        print('⚠️  API Key seems too short. Please check your .env file.');
        return;
      }

      // List of models to try (in order of preference)
      final modelsToTry = [
        // Explicit model paths expected by the API
        'models/gemini-1.5-flash-latest',
        'models/gemini-1.5-flash',
        'models/gemini-1.5-pro-latest',
        'models/gemini-1.5-pro',
        // Older stable models if the key does not have access to 1.5 models
        'models/gemini-1.0-pro-latest',
        'models/gemini-1.0-pro',
        'models/gemini-pro', // Last resort for legacy keys
      ];

      bool initialized = false;

      // Try each model until one works
      for (final modelName in modelsToTry) {
        try {
          print('🔄 Trying model: $modelName...');

          final testModel = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: Content.system(
              '''You are a helpful study assistant for StudiGo app. 
You help students with:
- Study schedule optimization
- Learning techniques and tips
- Motivation and stress management
- Subject-specific advice (Physics, Calculus, Programming, Languages, etc.)

Be friendly, supportive, and provide actionable advice. 
Use Indonesian language for better understanding.
Format responses with emojis and proper markdown for readability.''',
            ),
          );

          // Test the model with a simple query
          final testSession = testModel.startChat();
          final testResponse = await testSession
              .sendMessage(Content.text('Hi'))
              .timeout(const Duration(seconds: 10));

          if (testResponse.text != null && testResponse.text!.isNotEmpty) {
            _geminiModel = testModel;
            _chatSession = testSession;
            _workingModelName = modelName;
            initialized = true;
            print('   ✅ Success with $modelName!');
            break;
          }
        } catch (e) {
          print('   ❌ Failed: ${e.toString().split('\n')[0]}');
          continue;
        }
      }

      if (initialized && _workingModelName != null) {
        print('');
        print('✅ Gemini AI initialized successfully!');
        print('   Model: $_workingModelName');
        print('   You can now ask ANY question! 🚀');
        print('');
      } else {
        print('');
        print('❌ All models failed to initialize.');
        print('   Using template responses only.');
        print('');
        print('🔧 Troubleshooting:');
        print(
          '   1. Check API key is valid at https://aistudio.google.com/apikey',
        );
        print('   2. Verify internet connection');
        print('   3. Try regenerating API key');
        print('');
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing Gemini AI: $e');
      print('   Falling back to template responses.');
    }
  }

  void _initializeControllers() {
    // Get existing controllers if available
    try {
      if (Get.isRegistered<dynamic>(tag: 'ScheduleController')) {
        scheduleController = Get.find(tag: 'ScheduleController');
      }
      if (Get.isRegistered<dynamic>(tag: 'StreakController')) {
        streakController = Get.find(tag: 'StreakController');
      }
      if (Get.isRegistered<dynamic>(tag: 'SupabaseService')) {
        supabaseService = Get.find(tag: 'SupabaseService');
      }
    } catch (e) {
      print('Error getting controllers: $e');
    }
  }

  Future<void> _loadUserData() async {
    // Load actual schedule and task data from context passed by HomeController
    try {
      // The scheduleContext will contain tasks data passed from HomeController
      if (scheduleContext.value.isNotEmpty) {
        _parseScheduleContext();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _parseScheduleContext() {
    try {
      // Parse JSON string from scheduleContext
      final List<dynamic> parsed = jsonDecode(scheduleContext.value);
      userTasks.clear();
      userTasks.addAll(parsed.cast<Map<String, dynamic>>());
      print('Loaded ${userTasks.length} tasks from context');
    } catch (e) {
      print('Error parsing schedule context: $e');
    }
  }

  // Update tasks when new context is set
  void updateScheduleContext(List<Map<String, dynamic>> tasks) {
    userTasks.clear();
    userTasks.addAll(tasks);
    scheduleContext.value = jsonEncode(tasks);
    print('Updated ${userTasks.length} tasks in GeminiChat');
  }

  void _initializeWithGreeting() {
    messages.add({
      'text':
          'Halo! Saya Gemini AI dari StudiGo. Saya siap membantu Anda mengoptimalkan jadwal belajar, memberikan saran prioritas, dan menjawab pertanyaan terkait pembelajaran Anda. Bagaimana saya bisa membantu hari ini?',
      'isUser': false,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    messages.add({
      'text': message,
      'isUser': true,
      'timestamp': DateTime.now(),
    });

    messageController.clear();
    isLoading.value = true;

    try {
      // Simulate Gemini response with delay
      await Future.delayed(const Duration(milliseconds: 800));
      final response = await _generateGeminiResponse(message);

      if (response.isNotEmpty) {
        messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        messages.refresh();
      }
    } catch (e) {
      messages.add({
        'text': 'Maaf, terjadi kesalahan: ${e.toString()}',
        'isUser': false,
        'timestamp': DateTime.now(),
      });
      messages.refresh();
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _generateGeminiResponse(String userMessage) async {
    if (userMessage.isEmpty) {
      return 'Silakan ketik pesan terlebih dahulu!';
    }

    final lowerMessage = userMessage.toLowerCase();

    // Priority 1: Check for schedule-specific questions (use database context)
    if (lowerMessage.contains('prioritas') ||
        lowerMessage.contains('prioritize') ||
        lowerMessage.contains('prioritas apa') ||
        lowerMessage.contains('task apa') ||
        lowerMessage.contains('harus dikerjakan')) {
      return _generatePriorityResponse();
    } else if (lowerMessage.contains('jadwal') ||
        lowerMessage.contains('schedule') ||
        lowerMessage.contains('arrange') ||
        lowerMessage.contains('atur jadwal')) {
      return _generateScheduleResponse();
    }

    // Priority 2: Try Gemini API for general questions
    if (_chatSession != null && _geminiModel != null) {
      try {
        print('🤖 Calling Gemini API ($_workingModelName)...');

        // Add schedule context to the prompt if available
        String contextualPrompt = userMessage;
        if (userTasks.isNotEmpty) {
          final taskSummary = userTasks
              .map((t) => t['title'])
              .take(3)
              .join(', ');
          contextualPrompt = '''User's today schedule includes: $taskSummary

User question: $userMessage''';
          print('   📋 With schedule context: ${userTasks.length} tasks');
        }

        final response = await _chatSession!
            .sendMessage(Content.text(contextualPrompt))
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Request timeout - please try again');
              },
            );

        final text = response.text;
        if (text != null && text.isNotEmpty) {
          print('✅ Gemini API response received (${text.length} chars)');
          return text;
        } else {
          print('⚠️ Gemini API returned empty response');
          throw Exception('Empty response from API');
        }
      } catch (e) {
        print('❌ Error calling Gemini API: $e');

        // User-friendly error messages
        if (e.toString().contains('API key')) {
          print('   Falling back to template responses...');
        } else if (e.toString().contains('not found')) {
          print('   Model not available, falling back to templates...');
        } else if (e.toString().contains('quota')) {
          print('   API quota exceeded, falling back to templates...');
        } else if (e.toString().contains('timeout')) {
          return '⚠️ Koneksi timeout. Silakan coba lagi dalam beberapa saat.';
        }

        // Fall through to template responses
      }
    } else {
      print('⚠️ Gemini API not initialized (API key not set)');
      print('   Using template responses...');
    }

    // Priority 3: Fallback to template responses if API not available
    if (lowerMessage.contains('tips') ||
        lowerMessage.contains('cara') ||
        lowerMessage.contains('teknik') ||
        lowerMessage.contains('method') ||
        lowerMessage.contains('gimana cara')) {
      return '''Berikut tips belajar efektif dari saya:

✅ **Teknik Pomodoro**: 25 menit fokus + 5 menit istirahat
✅ **Spaced Repetition**: Review materi setelah 1 hari, 3 hari, 1 minggu
✅ **Active Recall**: Test diri sendiri, jangan hanya baca
✅ **Feynman Technique**: Jelaskan konsep dengan bahasa sederhana
✅ **Mind Mapping**: Visualisasi hubungan antar konsep
✅ **Chunking**: Bagi materi besar menjadi bagian-bagian kecil

Teknik mana yang paling Anda minati untuk diperdalam?''';
    } else if (lowerMessage.contains('motivasi') ||
        lowerMessage.contains('semangat') ||
        lowerMessage.contains('capai') ||
        lowerMessage.contains('percaya diri')) {
      return '''Ingatlah tujuan Anda! 🎯

Setiap sesi belajar yang Anda lakukan hari ini adalah investasi untuk masa depan yang lebih cerah. 

💪 Motivasi Harian:
- Kecil-kecilan konsisten > Besar-besaran sesekali
- Progres > Kesempurnaan
- Hari ini adalah awal, bukan akhir
- Setiap hambatan adalah kesempatan belajar

Anda sudah memulai dengan baik dengan menggunakan StudiGo. Terus semangat! 🚀''';
    } else if (lowerMessage.contains('stress') ||
        lowerMessage.contains('overwhelm') ||
        lowerMessage.contains('pusing') ||
        lowerMessage.contains('bingung') ||
        lowerMessage.contains('tidak fokus')) {
      return '''Merasa overwhelmed adalah normal. Sini kita break it down:

🧘 **Strategi Mengatasi Stress Belajar:**

1. **Prioritas** - Fokus pada 3 task paling penting saja
2. **Breakdown** - Bagi task besar jadi sub-task kecil
3. **Reward** - Berikan hadiah setelah menyelesaikan milestone
4. **Istirahat** - Ambil break setiap 25-30 menit
5. **Support** - Ajak teman belajar bersama
6. **Gerak** - Olahraga 30 menit untuk clear head

Mau kita buat action plan yang manageable untuk hari ini?''';
    } else if (lowerMessage.contains('fisika') ||
        lowerMessage.contains('kalkulus') ||
        lowerMessage.contains('matematika') ||
        lowerMessage.contains('programming') ||
        lowerMessage.contains('bahasa')) {
      final subject = _detectSubject(userMessage);
      return '''Bagus! Mari kita fokus pada $subject.

📚 **Strategi Belajar untuk $subject:**

**Fase 1: Understanding (30%)**
- Pahami konsep dasar
- Jangan langsung hafal
- Gunakan visualisasi/diagram

**Fase 2: Practice (50%)**
- Kerjakan contoh soal
- Variasikan jenis soal
- Track progress Anda

**Fase 3: Review (20%)**
- Review kesalahan
- Tanya yang tidak paham
- Praktik soal sulit

💡 Tips khusus: Belajar $subject paling efektif 2-3 jam sebelum puncak energi Anda.

Ada pertanyaan spesifik tentang $subject?''';
    } else {
      return '''Pertanyaan yang bagus! 😊

Untuk memberikan saran yang lebih spesifik dan akurat, saya bisa membantu dengan:

📋 **Topik yang saya kuasai:**
- Manajemen jadwal belajar
- Teknik & tips belajar efektif
- Prioritas tugas harian
- Motivasi & mengatasi stress
- Tips per-subject (Fisika, Kalkulus, Programming, Bahasa, dll)

🎯 **Coba tanyakan:**
- "Apa prioritas aku hari ini?"
- "Gimana cara fokus saat belajar?"
- "Tips untuk Fisika gimana?"
- "Saya stress, bagaimana?"

Apa yang bisa saya bantu untuk Anda hari ini? 📚✨''';
    }
  }

  String _detectSubject(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('fisika')) return 'Fisika';
    if (lower.contains('kalkulus') || lower.contains('matematika'))
      return 'Kalkulus';
    if (lower.contains('programming') || lower.contains('coding'))
      return 'Programming';
    if (lower.contains('bahasa')) return 'Bahasa';
    return 'Subjek Anda';
  }

  void setScheduleContext(String context) {
    scheduleContext.value = context;
  }

  // New methods to generate responses from actual database data
  String _generatePriorityResponse() {
    if (userTasks.isEmpty) {
      return '''Saya belum melihat jadwal tugas Anda hari ini. 

Untuk memberikan rekomendasi prioritas yang akurat, silakan:
1. Tambahkan jadwal di menu Schedule
2. Kembali ke sini untuk mendapat saran prioritas

Atau tanya saya tentang tips belajar umum! 📚''';
    }

    // Sort tasks by time (earliest first)
    final sortedTasks = List<Map<String, dynamic>>.from(userTasks);
    sortedTasks.sort((a, b) {
      final aTime = DateTime.parse(a['start_time'].toString());
      final bTime = DateTime.parse(b['start_time'].toString());
      return aTime.compareTo(bTime);
    });

    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.writeln(
      'Berdasarkan jadwal Anda hari ini, berikut prioritas yang saya rekomendasikan:\n',
    );

    for (int i = 0; i < sortedTasks.length && i < 5; i++) {
      final task = sortedTasks[i];
      final title = task['title'] ?? 'Task';
      final startTime = DateTime.parse(task['start_time'].toString());
      final timeStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final duration = task['duration'] ?? 60;
      final durationStr = duration >= 60
          ? '${(duration / 60).toStringAsFixed(1)} jam'
          : '$duration menit';

      final isPast = startTime.isBefore(now);
      final isCompleted = task['isCompleted'] == true;

      String status = '';
      if (isCompleted) {
        status = '✅ Selesai';
      } else if (isPast) {
        status = '⚠️ Terlewat';
      } else {
        status = '🔜 Mendatang';
      }

      buffer.writeln('${i + 1}. **$title** - $timeStr ($durationStr) $status');

      // Add contextual advice
      if (i == 0 && !isCompleted && !isPast) {
        buffer.writeln('   💡 Prioritas tertinggi! Mulai dengan task ini.');
      }
    }

    buffer.writeln('\n**Tips Prioritas:**');
    buffer.writeln(
      '✅ Selesaikan task paling penting/sulit saat energi masih tinggi',
    );
    buffer.writeln(
      '✅ Gunakan teknik Pomodoro (25 menit fokus + 5 menit break)',
    );
    buffer.writeln('✅ Hindari multitasking, fokus satu task hingga selesai');

    return buffer.toString();
  }

  String _generateScheduleResponse() {
    if (userTasks.isEmpty) {
      return '''Jadwal Anda hari ini masih kosong. 

Untuk optimasi jadwal belajar yang lebih baik, saya sarankan:

📅 **Struktur Harian Ideal:**
- 06:00-07:00: Rutinitas pagi + breakfast
- 07:00-09:00: Blok belajar utama (subjek berat)
- 09:00-10:00: Istirahat & snack
- 10:00-12:00: Blok belajar kedua (subjek medium)
- 12:00-13:30: Makan siang & jeda
- 13:30-15:00: Blok belajar ketiga
- 15:00-17:00: Aktivitas ekstrakurikuler/olahraga
- 17:00-18:30: Dinner & relaksasi
- 18:30-20:00: Review & persiapan

Silakan tambahkan jadwal di menu Schedule! 📝''';
    }

    final sortedTasks = List<Map<String, dynamic>>.from(userTasks);
    sortedTasks.sort((a, b) {
      final aTime = DateTime.parse(a['start_time'].toString());
      final bTime = DateTime.parse(b['start_time'].toString());
      return aTime.compareTo(bTime);
    });

    final buffer = StringBuffer();
    buffer.writeln('📅 **Jadwal Anda Hari Ini:**\n');

    for (int i = 0; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      final title = task['title'] ?? 'Task';
      final startTime = DateTime.parse(task['start_time'].toString());
      final endTime = DateTime.parse(task['end_time'].toString());
      final startStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      final isCompleted = task['isCompleted'] == true;

      final icon = isCompleted ? '✅' : '⏰';
      buffer.writeln('$icon **$startStr - $endStr**: $title');
    }

    buffer.writeln('\n**Saran Optimasi:**');

    // Calculate total study time
    int totalMinutes = 0;
    for (var task in sortedTasks) {
      final duration = task['duration'] ?? 60;
      totalMinutes += duration as int;
    }
    final hours = (totalMinutes / 60).toStringAsFixed(1);

    buffer.writeln('📊 Total waktu belajar: $hours jam');

    if (totalMinutes > 240) {
      buffer.writeln('⚠️ Jadwal cukup padat! Pastikan ada waktu istirahat.');
    } else if (totalMinutes < 120) {
      buffer.writeln(
        '💡 Pertimbangkan menambah waktu belajar untuk hasil optimal.',
      );
    } else {
      buffer.writeln('✅ Durasi belajar sudah ideal!');
    }

    buffer.writeln(
      '\n💡 Jangan lupa break setiap 25-30 menit untuk menjaga fokus!',
    );

    return buffer.toString();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
