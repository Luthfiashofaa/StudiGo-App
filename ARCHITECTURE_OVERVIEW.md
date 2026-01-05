# 🎨 Gemini AI - Visual Overview & Architecture

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    StudiGo Home Screen                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐                                      │
│  │ Avatar       │ Halo, [User]!                        │
│  │ + Name       │ Siap capai target?                   │
│  └──────────────┘                                      │
│                                                         │
│  ┌─────────────────────────────────────────────┐       │
│  │ ✨  AI menyarankan fokus pada [Task]  →    │       │
│  │                                             │       │
│  │ Tap untuk buka Gemini AI                   │       │
│  └─────────────────────────────────────────────┘       │
│         (Dynamic Suggestion Card)                       │
│                                                         │
│  ┌─────────────────────────────────────────────┐       │
│  │ Progress                            48%     │       │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░       │       │
│  │ Dari target harian yang tercapai            │       │
│  └─────────────────────────────────────────────┘       │
│                                                         │
│  Tugas Hari Ini                                        │
│  ┌─────────────────┐  ┌─────────────────┐            │
│  │ 📐 Kalkulus   ○│  │ 🧪 Fisika     ○│            │
│  └─────────────────┘  └─────────────────┘            │
│  ┌─────────────────┐  ┌─────────────────┐            │
│  │ 💻 Programming ○│  │ 📖 Bahasa     ○│            │
│  └─────────────────┘  └─────────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          ↓ onTap
                    Navigate to Chat
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Gemini Chat Screen                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ← Gemini AI                                     ✨    │
│                                                         │
│  ┌────────────────────────────────────────────┐        │
│  │ Halo! Saya Gemini AI dari StudiGo. Saya   │        │
│  │ siap membantu Anda mengoptimalkan jadwal  │        │
│  │ belajar...                                 │        │
│  └────────────────────────────────────────────┘        │
│                                                         │
│                         ┌──────────────────────┐       │
│                         │ Tolong prioritas aku │       │
│                         │ hari ini?            │       │
│                         └──────────────────────┘       │
│                                                         │
│  ┌────────────────────────────────────────────┐        │
│  │ Berdasarkan jadwal Anda, prioritasnya:    │        │
│  │ 1. Kalkulus - 2 jam pagi...               │        │
│  │ 2. Fisika - 1,5 jam...                    │        │
│  │ ...                                        │        │
│  └────────────────────────────────────────────┘        │
│                                                         │
│  ┌─────────────────────────────────────────┐          │
│  │ [Type message...            ]  [➤]      │          │
│  └─────────────────────────────────────────┘          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  User Action: Task Completion Toggle                      │
│                                                             │
│  HomeView._TaskCard.onToggle()                            │
│           │                                                │
│           ↓                                                │
│  HomeController.toggleTaskCompletion(index)               │
│           │                                                │
│           ├─ Update todayTasks[index]['isCompleted']      │
│           │                                                │
│           ├─ Update completedTasksCount                   │
│           │                                                │
│           ├─ Persist to local storage                     │
│           │                                                │
│           ├─ Call _updateDailyProgress()                  │
│           │     │                                         │
│           │     ├─ Calculate progress percentage          │
│           │     │                                         │
│           │     ├─ Update streak helper                   │
│           │     │                                         │
│           │     └─ Call _generateAISuggestion() ← KEY     │
│           │          │                                    │
│           │          ├─ Check if tasks empty              │
│           │          │                                    │
│           │          ├─ Get incomplete tasks              │
│           │          │                                    │
│           │          ├─ Check time of day                 │
│           │          │                                    │
│           │          ├─ Generate context-aware message    │
│           │          │                                    │
│           │          └─ Update observables:               │
│           │              - aiSuggestion                   │
│           │              - suggestedTaskTitle             │
│           │              - isGeneratingSuggestion         │
│           │                                               │
│           └─ HomeView listens to aiSuggestion observable   │
│                │                                          │
│                └─ Rebuilds UI with new suggestion        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎬 Navigation Flow

```
┌──────────────────┐
│   Home Screen    │
│  (HomeView)      │
│                  │
│ ┌──────────────┐ │
│ │ Suggestion   │ │
│ │ Card (Obx)   │ │
│ │              │ │
│ │ onTap:       │ │
│ │ openGeminiAI │ │
│ └──────┬───────┘ │
└────────┼──────────┘
         │
         ↓
┌──────────────────────────────────────┐
│ HomeController.openGeminiAI()        │
│                                      │
│ 1. Check if GeminiChatController    │
│    is registered                    │
│    ├─ No → Get.put() register it   │
│    └─ Yes → Continue                │
│                                      │
│ 2. Set schedule context              │
│    └─ Chat aware of user's schedule │
│                                      │
│ 3. Navigate                         │
│    └─ Get.toNamed('/gemini-chat')   │
└──────────────────────────────────────┘
         │
         ↓
┌──────────────────────────┐
│  Route Configuration     │
│ (/gemini-chat)          │
│                         │
│ Get.put(() =>          │
│  GeminiChatView()       │
│ )                       │
└──────────┬──────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│     Gemini Chat Screen               │
│    (GeminiChatView)                 │
│                                      │
│ ┌────────────────────────────────┐  │
│ │ Message List (Obx)             │  │
│ │ - User messages (blue)         │  │
│ │ - AI messages (white)          │  │
│ │ - Scrollable history           │  │
│ └────────────────────────────────┘  │
│                                      │
│ ┌────────────────────────────────┐  │
│ │ Input Field + Send Button      │  │
│ │ - TextField                    │  │
│ │ - Send icon button             │  │
│ │ - Loading indicator            │  │
│ └────────────────────────────────┘  │
│                                      │
│ ← Back button → Returns to home      │
└──────────────────────────────────────┘
```

---

## 💬 Chat Message Flow

```
User Types Message
        │
        ↓
User Taps Send Button
        │
        ↓
GeminiChatController.sendMessage()
        │
        ├─ Get message from TextEditingController
        │
        ├─ Validate (not empty)
        │
        ├─ Add to messages list (user message)
        │
        ├─ Clear input field
        │
        ├─ Set isLoading = true
        │
        ├─ Call _generateGeminiResponse(message)
        │  │
        │  ├─ Detect keywords
        │  │
        │  ├─ Route to appropriate response
        │  │
        │  └─ Return formatted response
        │
        ├─ Add to messages list (AI message)
        │
        └─ Set isLoading = false
                │
                ↓
        HomeView Listens to messages.obs
                │
                ↓
        Rebuilds ListViewBuilder
                │
                ↓
        Displays new messages
```

---

## 🧠 Suggestion Generation Algorithm

```
START: _generateAISuggestion()
  │
  ├─ Set isGeneratingSuggestion = true
  │
  ├─ Check: Are there tasks?
  │  │
  │  ├─ NO  → Return "Tambahkan jadwal belajar..."
  │  │
  │  └─ YES → Continue
  │
  ├─ Get all incomplete tasks
  │  │
  │  ├─ NONE → Return "Hebat! Semua selesai! 🎉"
  │  │
  │  └─ SOME → Continue with first incomplete
  │
  ├─ Get next task title
  │
  ├─ Call _generateContextAwareSuggestion()
  │  │
  │  ├─ Get current hour (0-23)
  │  │
  │  ├─ Determine time greeting
  │  │  ├─ 00-11 → "pagi yang sempurna..."
  │  │  ├─ 12-16 → "waktu yang tepat..."
  │  │  └─ 17-23 → "malam yang ideal..."
  │  │
  │  ├─ Count pending tasks
  │  │
  │  ├─ Calculate progress percentage
  │  │
  │  ├─ Hash task title (for consistency)
  │  │
  │  ├─ Select suggestion template (0-4)
  │  │  ├─ Template 0: Time-based
  │  │  ├─ Template 1: Priority-based
  │  │  ├─ Template 2: Motivation
  │  │  ├─ Template 3: Progress-based
  │  │  └─ Template 4: Technique-based
  │  │
  │  └─ Return formatted suggestion
  │
  ├─ Update observables
  │  ├─ aiSuggestion = suggestion text
  │  └─ suggestedTaskTitle = task name
  │
  ├─ Handle errors
  │  └─ Return fallback suggestion
  │
  └─ Set isGeneratingSuggestion = false
END
```

---

## 🎨 UI Component Hierarchy

```
HomeView (GetView<HomeController>)
├── Stack (background blobs)
│
└── SafeArea
    └── Align (top center)
        └── ConstrainedBox
            └── Column
                ├── Row (Avatar + Name)
                ├── Text ("Siap capai target?")
                │
                ├── Obx() ← Reactive
                │   └── GestureDetector
                │       └── Container (Suggestion Card)
                │           ├── Container (Icon)
                │           │   └── Icon | LoadingSpinner
                │           └── Column (Text Content)
                │               ├── Text (aiSuggestion)
                │               └── Row (CTA)
                │
                ├── Container (Progress Card)
                │   ├── Row (Header)
                │   ├── Obx()
                │   │   └── Row (Progress %)
                │   └── Obx()
                │       └── ClipRRect (Progress Bar)
                │
                ├── Row (Section Title)
                │
                └── Obx()
                    └── GridView | Column (Tasks)
                        └── _TaskCard
                            ├── Container (Icon)
                            ├── Text (Title)
                            └── IconButton (Checkbox)
```

---

## 🌐 State Management Structure

```
HomeController (GetxController)
│
├── Observables (Reactive)
│   ├── userName
│   ├── avatarUrl
│   ├── isLoadingUser
│   ├── todayTasks (RxList)
│   ├── completedTasksCount
│   ├── aiSuggestion ← NEW
│   ├── suggestedTaskTitle ← NEW
│   └── isGeneratingSuggestion ← NEW
│
├── Methods
│   ├── onInit()
│   ├── _initScheduleListener()
│   ├── _loadUserData()
│   ├── _loadTodayTasks()
│   ├── toggleTaskCompletion()
│   ├── _updateDailyProgress()
│   ├── _generateAISuggestion() ← NEW
│   ├── _generateContextAwareSuggestion() ← NEW
│   ├── openGeminiAI() ← UPDATED
│   ├── _setScheduleContextForChat() ← NEW
│   ├── _buildScheduleContext() ← NEW
│   └── ...others
│
└── Dependencies
    ├── SupabaseService
    ├── ScheduleController
    ├── StreakController
    └── GeminiChatController ← NEW

GeminiChatController (GetxController)
│
├── Observables (Reactive)
│   ├── messages (RxList)
│   ├── isLoading
│   └── scheduleContext
│
├── Controllers
│   └── messageController (TextEditingController)
│
├── Methods
│   ├── onInit()
│   ├── _initializeWithGreeting()
│   ├── sendMessage()
│   ├── _generateGeminiResponse()
│   ├── setScheduleContext()
│   └── onClose()
│
└── No external dependencies
```

---

## 📱 Responsive Breakpoints

```
Mobile (< 600px)
├── Width: < 600
├── Padding: 16-20px
├── Font Size: 14-18px
├── Avatar Radius: 28px
├── Card Height: Standard
└── Grid: Single column

         ↔ 600px breakpoint

Tablet (≥ 600px)
├── Width: ≥ 600
├── Padding: 32-48px
├── Font Size: 15-22px
├── Avatar Radius: 34px
├── Card Height: Optimized
└── Grid: 2 columns
```

---

## 🔌 Future API Integration Point

```
Current (v1.0.0):
_generateGeminiResponse(String userMessage) {
  // Mock response logic
  // Pattern matching on keywords
  // Return hardcoded response
}
           │
           ↓
Future (v1.1.0):
_generateGeminiResponse(String userMessage) async {
  // Real API call
  final model = GenerativeModel(...);
  final response = await model.generateContent([
    Content.text(userMessage),
  ]);
  return response.text ?? 'No response';
}
```

---

## ✅ Testing Points

```
├─ HomeScreen
│  ├─ Load home
│  ├─ Check suggestion appears
│  ├─ Verify text is dynamic (not hardcoded)
│  ├─ Check loading spinner
│  ├─ Verify suggestion updates on task toggle
│  └─ Tap suggestion → Navigate to chat
│
├─ GeminiChat
│  ├─ See greeting message
│  ├─ Type message
│  ├─ Send message
│  ├─ See user message (blue, right)
│  ├─ See AI response (white, left)
│  ├─ Check loading indicator
│  ├─ Multiple messages in history
│  ├─ Scroll through messages
│  ├─ Back button works
│  └─ Return to home
│
└─ Responsive
   ├─ Test on mobile (< 600px)
   ├─ Test on tablet (≥ 600px)
   ├─ Check padding & spacing
   ├─ Verify fonts sizes
   ├─ Check colors & gradients
   └─ Test all gestures
```

---

**Architecture Overview Complete!** 🎉

This visual documentation should help understand the entire flow and structure of the Gemini AI integration.

