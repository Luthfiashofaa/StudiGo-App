# 🤖 Gemini AI Integration Setup

## Overview
StudiGo menggunakan Google Gemini AI untuk memberikan respons AI yang cerdas dan kontekstual kepada pengguna. Integrasi ini memungkinkan pengguna bertanya tentang apa saja, tidak hanya terbatas pada schedule.

## Features
- ✅ **Pertanyaan Umum**: Tanya apa saja seperti "Apa itu fotosintesis?", "Bagaimana cara belajar efektif?"
- ✅ **Schedule-Aware**: AI mengetahui jadwal user hari ini
- ✅ **Context-Aware Responses**: Jawaban yang disesuaikan dengan data user
- ✅ **Hybrid Approach**: Prioritas pada database context untuk pertanyaan schedule

## Setup Instructions

### 1. Dapatkan Gemini API Key

1. Kunjungi [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Login dengan akun Google Anda
3. Klik **"Get API Key"** atau **"Create API Key"**
4. Copy API key yang digenerate

### 2. Set API Key di .env File

Edit file `.env` di root project:

```dotenv
SUPABASE_URL=https://batonwnqdwxaxcsjykxw.supabase.co
SUPABASE_ANON_KEY=your_supabase_key
RESET_PASSWORD_REDIRECT=studigo://auth-callback
GEMINI_API_KEY=YOUR_ACTUAL_GEMINI_API_KEY_HERE
```

**⚠️ PENTING:**
- Ganti `YOUR_ACTUAL_GEMINI_API_KEY_HERE` dengan API key asli Anda
- Jangan commit `.env` file ke Git (sudah ada di `.gitignore`)
- API key bersifat rahasia, jangan share ke publik

### 3. Restart Aplikasi

Setelah menambahkan API key:
```bash
flutter clean
flutter pub get
flutter run
```

## How It Works

### Hybrid Response System

```dart
Priority 1: Schedule-Specific Questions (Database Context)
  ↓
  "prioritas", "jadwal" → _generatePriorityResponse() / _generateScheduleResponse()
  
Priority 2: General Questions (Gemini API)
  ↓
  Semua pertanyaan lain → Google Gemini API
  
Priority 3: Fallback (Template Responses)
  ↓
  Jika API error → Template responses
```

### Context Injection

Ketika user bertanya, AI mendapat context:
```
User's today schedule includes: Kalkulus, Fisika, Programming

User question: Bagaimana cara belajar Fisika?
```

Sehingga jawaban lebih relevan dan personal.

## Example Conversations

### Schedule Questions (Database Context)
```
User: "Apa prioritas aku hari ini?"
AI: Berdasarkan jadwal Anda hari ini:
     1. **Kalkulus** - 07:00 (2.0 jam) 🔜 Mendatang
     2. **Fisika** - 10:00 (1.5 jam) 🔜 Mendatang
     ...
```

### General Questions (Gemini API)
```
User: "Jelaskan tentang fotosintesis"
AI: Fotosintesis adalah proses yang digunakan tumbuhan untuk...

User: "Tips belajar matematika?"
AI: Berikut tips belajar matematika yang efektif:
     1. Pahami konsep, bukan hafal rumus
     2. Latihan soal beragam...
```

### Context-Aware Questions
```
User: "Gimana cara belajar Fisika?"
AI: [Mengetahui user punya jadwal Fisika hari ini]
    Untuk Fisika yang akan kamu pelajari jam 10:00 nanti:
    - Pastikan review materi kemarin dulu
    - Fokus pada konsep dasar...
```

## API Limits & Pricing

**Gemini 1.5 Flash (Free Tier):**
- ✅ 15 RPM (Requests Per Minute)
- ✅ 1 million TPM (Tokens Per Minute)
- ✅ 1,500 RPD (Requests Per Day)

**Untuk StudiGo App:**
- Chat messages < 1000 tokens per request
- Rata-rata user: 10-50 messages per day
- Free tier sangat cukup untuk development & testing

**Upgrade jika needed:**
- Pay-as-you-go: $0.15 / 1M input tokens
- Production apps dengan banyak user

## Security Best Practices

✅ **DO:**
- Store API key di `.env` file
- Add `.env` to `.gitignore`
- Use environment variables
- Rotate keys periodically

❌ **DON'T:**
- Hardcode API key in code
- Commit API key to Git
- Share API key publicly
- Use same key for dev & prod

## Troubleshooting

### API Key Not Working
```
⚠️ Gemini API key not set. Using template responses.
```
**Solution:** Check `.env` file has correct `GEMINI_API_KEY=...`

### API Error 429 (Rate Limit)
```
Error calling Gemini API: Rate limit exceeded
```
**Solution:** 
- Wait 1 minute before retry
- Upgrade to paid tier if consistent issue

### API Error 400 (Invalid Key)
```
Error calling Gemini API: API key not valid
```
**Solution:**
- Regenerate API key di AI Studio
- Update `.env` file
- Restart app

### No Response from API
```
Error calling Gemini API: Network error
```
**Solution:**
- Check internet connection
- Verify API key is active
- Check Google AI Studio status

## Testing

### Test API Integration
1. Run app dengan valid API key
2. Open Gemini chat
3. Tanya pertanyaan umum: "Apa itu AI?"
4. Verify response dari Gemini (bukan template)

### Test Schedule Context
1. Add jadwal di Schedule menu
2. Open Gemini chat
3. Tanya: "Prioritas aku hari ini?"
4. Verify response show actual tasks dari database

### Test Fallback
1. Set invalid API key atau remove API key
2. Open Gemini chat
3. Tanya apapun
4. Verify app still works dengan template responses

## Architecture

```
HomeController
    ↓ (pass tasks)
GeminiChatController
    ↓
    ├─→ _generatePriorityResponse() [Database]
    ├─→ _generateScheduleResponse() [Database]
    └─→ Gemini API [General Questions]
```

## Future Enhancements

🚀 **Planned Features:**
- Voice input/output integration
- Multi-language support (English/Indonesian)
- Image analysis for study materials
- Personalized learning recommendations
- Study session tracking & analytics

## Support

Jika ada masalah:
1. Check [Google AI Studio Docs](https://ai.google.dev/docs)
2. Check API key validity
3. Review logs: `print()` statements in code
4. Raise issue di repository

---

**Happy Coding! 🎉**
