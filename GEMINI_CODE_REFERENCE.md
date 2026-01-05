# 📋 Code Snippets & References

## 🎯 Suggestion Generation Logic

### How Suggestions are Generated

```dart
// In home_controller.dart - _generateAISuggestion()

1. Check if tasks exist
   ├─ Empty → "Tambahkan jadwal belajar untuk hari ini!"
   └─ Has tasks → Continue

2. Get incomplete tasks
   ├─ All completed → "Hebat! Semua tugas selesai! 🎉"
   └─ Has pending → Continue

3. Get next task to work on
   └─ Pick first incomplete task

4. Generate context-aware suggestion
   ├─ Check time of day (06-12, 12-17, 17+)
   ├─ Count pending tasks
   ├─ Calculate progress percentage
   └─ Pick suggestion from 5 templates

5. Update observables
   ├─ aiSuggestion = generated text
   └─ suggestedTaskTitle = task name
```

### Suggestion Templates

```dart
final suggestions = [
  // Template 1: Time-based focus
  'AI menyarankan kamu fokus pada "$taskTitle" sekarang - 
   ini adalah $timeGreeting tugas ini',
  
  // Template 2: Priority with task count
  'Prioritas: Kerjakan "$taskTitle" dulu untuk momentum yang lebih baik. 
   Ada $pendingCount tugas lagi hari ini',
  
  // Template 3: Energy & motivation
  'Energimu masih bagus! Ambil kesempatan ini untuk menguasai 
   "$taskTitle" dengan baik',
  
  // Template 4: Progress tracking
  'Dengan penyelesaian "$taskTitle", progresmu akan mencapai 
   ${(progress + (100 ~/ (pendingCount + 1))).clamp(0, 100)}%',
  
  // Template 5: Technique-based
  'Fokus pada "$taskTitle" untuk 45 menit dengan Pomodoro technique 
   - pasti bisa!',
];
```

### Time of Day Logic

```dart
final time = DateTime.now().hour;

if (time < 12) {
  timeGreeting = 'pagi yang sempurna untuk fokus pada';
} else if (time < 17) {
  timeGreeting = 'waktu yang tepat untuk menyelesaikan';
} else {
  timeGreeting = 'malam yang ideal untuk mereview';
}
```

---

## 💬 Chat Response Patterns

### Keyword Detection

```dart
Future<String> _generateGeminiResponse(String userMessage) async {
  final lowerMessage = userMessage.toLowerCase();

  if (lowerMessage.contains('prioritas') || 
      lowerMessage.contains('prioritize')) {
    return _getPriorityResponse();
  } 
  else if (lowerMessage.contains('jadwal') || 
           lowerMessage.contains('schedule')) {
    return _getScheduleResponse();
  }
  else if (lowerMessage.contains('tips') || 
           lowerMessage.contains('cara')) {
    return _getTipsResponse();
  }
  else if (lowerMessage.contains('motivasi') || 
           lowerMessage.contains('semangat')) {
    return _getMotivationResponse();
  }
  else if (lowerMessage.contains('stress') || 
           lowerMessage.contains('overwhelm')) {
    return _getStressResponse();
  }
  else {
    return _getGeneralResponse();
  }
}
```

### Response Examples

**Priority Response:**
```
Berdasarkan jadwal Anda, berikut prioritas yang saya rekomendasikan:

1. **Kalkulus** - Topik ini membutuhkan pemahaman konsep yang mendalam. 
   Prioritaskan 2 jam pagi dengan fokus penuh
   
2. **Fisika** - Praktikum lab memerlukan persiapan, alokasikan 1,5 jam

3. **Programming** - Coding memerlukan hands-on practice, 1 jam untuk solving problems

4. **Bahasa** - Review vocabulary bisa dilakukan di sela-sela aktivitas

💡 Tips: Mulai dengan subjek paling sulit saat energi masih peak (pagi/siang awal).
```

**Schedule Optimization Response:**
```
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

Apakah Anda ingin saya menyesuaikan dengan jadwal spesifik Anda?
```

---

## 🎨 UI Components

### Suggestion Card

```dart
Obx(
  () => GestureDetector(
    onTap: () => controller.openGeminiAI(),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with loading
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: controller.isGeneratingSuggestion.value
                ? CircularProgressIndicator(/* ... */)
                : Icon(Icons.auto_awesome),
          ),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.aiSuggestion.value),
                Row(children: [
                  Text('Tap untuk buka Gemini AI'),
                  Icon(Icons.arrow_forward),
                ]),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### Chat Message Bubble

```dart
Align(
  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(
    constraints: BoxConstraints(maxWidth: maxWidth * 0.75),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: isUser
          ? const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)])
          : LinearGradient(colors: [Colors.white, Colors.white.withOpacity(0.95)]),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14),
        bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(4),
        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(14),
      ),
      boxShadow: [
        BoxShadow(
          color: isUser
              ? const Color(0xFF4A90E2).withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      message['text'] as String,
      style: TextStyle(
        color: isUser ? Colors.white : Colors.black87,
        fontSize: 14,
        height: 1.5,
      ),
    ),
  ),
)
```

---

## 🔀 Navigation Flow

### From Home to Chat

```dart
// home_controller.dart - openGeminiAI()
Future<void> openGeminiAI() async {
  try {
    // Register controller if not exists
    if (!Get.isRegistered<GeminiChatController>()) {
      Get.put(GeminiChatController());
    }
    
    // Set schedule context
    final chatController = Get.find<GeminiChatController>();
    _setScheduleContextForChat(chatController);
    
    // Navigate
    Get.toNamed('/gemini-chat');
  } catch (e) {
    debugPrint('Error opening Gemini AI: $e');
    // Fallback
    openGeminiInBrowser();
  }
}
```

### Context Building

```dart
String _buildScheduleContext() {
  if (todayTasks.isEmpty) {
    return 'User tidak memiliki tugas hari ini.';
  }

  final taskList = todayTasks
      .map((t) => '- ${t['title']} (${t['isCompleted'] == true ? 'Selesai' : 'Belum'})')
      .join('\n');

  return '''Jadwal hari ini:
$taskList

Progress: ${progressPercentage}%''';
}
```

---

## 📊 Observable Data Flow

### HomeController Observables

```dart
// User info
final userName = 'User'.obs;
final avatarUrl = ''.obs;
final isLoadingUser = false.obs;

// Task tracking
final RxList<Map<String, dynamic>> todayTasks = <Map<String, dynamic>>[].obs;
final completedTasksCount = 0.obs;

// AI suggestion
final aiSuggestion = ''.obs;           // e.g., "AI menyarankan..."
final suggestedTaskTitle = ''.obs;     // e.g., "Kalkulus"
final isGeneratingSuggestion = false.obs;
```

### GeminiChatController Observables

```dart
// Chat messages
final messages = <Map<String, dynamic>>[].obs;

// Loading state
final isLoading = false.obs;

// Schedule context
final scheduleContext = ''.obs;

// Message format
{
  'text': String,        // Konten pesan
  'isUser': bool,        // true = user, false = AI
  'timestamp': DateTime, // Waktu dikirim
}
```

---

## 🔗 Route Configuration

### app_routes.dart

```dart
abstract class Routes {
  static const geminiChat = _Paths.geminiChat;
}

abstract class _Paths {
  static const geminiChat = '/gemini-chat';
}

// Usage: Get.toNamed(Routes.geminiChat);
```

### app_pages.dart

```dart
GetPage(
  name: _Paths.geminiChat,
  page: () => const GeminiChatView(),
  // Optional: Add binding if needed
  // binding: GeminiChatBinding(),
),
```

---

## ⚙️ Task Completion Toggle

### How It Updates Suggestions

```dart
void toggleTaskCompletion(int index) {
  if (index >= 0 && index < todayTasks.length) {
    final task = todayTasks[index];
    final newStatus = !(task['isCompleted'] ?? false);

    // Update state
    todayTasks[index]['isCompleted'] = newStatus;
    todayTasks.refresh();

    // Update counter
    completedTasksCount.value = todayTasks
        .where((task) => task['isCompleted'] == true)
        .length;

    // Persist
    _persistTodayCompletion();

    // Update UI & suggestion
    _updateDailyProgress();  // ← This triggers _generateAISuggestion()
  }
}
```

---

## 🎯 Responsive Breakpoint

### Mobile vs Tablet

```dart
LayoutBuilder(builder: (context, constraints) {
  final bool isTablet = constraints.maxWidth >= 600;
  
  // Mobile layout
  if (!isTablet) {
    final horizontalPadding = 20.0;
    final fontSize = 14.0;
    // ... mobile specific code
  }
  
  // Tablet layout
  else {
    final horizontalPadding = 48.0;
    final fontSize = 15.0;
    // ... tablet specific code
  }
})
```

---

## 🚨 Error Handling

### Chat Error Handling

```dart
try {
  isLoading.value = true;
  final response = await _generateGeminiResponse(message);
  messages.add({
    'text': response,
    'isUser': false,
    'timestamp': DateTime.now(),
  });
} on SocketException {
  messages.add({
    'text': 'Koneksi internet bermasalah. Silakan cek koneksi Anda.',
    'isUser': false,
  });
} catch (e) {
  messages.add({
    'text': 'Maaf, terjadi kesalahan. Silakan coba lagi: ${e.toString()}',
    'isUser': false,
  });
} finally {
  isLoading.value = false;
}
```

---

## 📝 Future API Integration

### Simple Google Gemini Integration

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatController extends GetxController {
  late final GenerativeModel _model;
  late GenerativeAIClient _client;

  @override
  void onInit() {
    super.onInit();
    _initializeGemini();
    _initializeWithGreeting();
  }

  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'YOUR_API_KEY_HERE',
    );
  }

  Future<String> _generateGeminiResponse(String userMessage) async {
    try {
      final chat = _model.startChat();
      final response = await chat.sendMessage(
        Content.text(userMessage),
      );
      return response.text ?? 'No response from Gemini';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}
```

---

**Last Updated**: January 5, 2026
**Version**: 1.0.0
