# QUICK START - Firebase Notifications

## 30 Detik Setup

1. **Get FCM Key**
   ```
   Firebase Console → studigo-9876e → Settings → Cloud Messaging
   Copy "Server API Key"
   ```

2. **Create Table** (Supabase SQL Editor)
   ```sql
   CREATE TABLE public.reminders (
     id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id uuid, device_token text, title text, body text,
     reminder_at timestamptz, sent boolean DEFAULT false,
     created_at timestamptz DEFAULT now()
   );
   CREATE INDEX reminders_due_idx ON public.reminders (sent, reminder_at);
   ```

3. **Deploy Function**
   ```bash
   cd studigo
   supabase login
   supabase secrets set FCM_SERVER_KEY "YOUR_KEY" --project-ref batonwnqdwxaxcsjykxw
   supabase functions deploy send-reminder --project-ref batonwnqdwxaxcsjykxw
   ```

4. **Setup Cron** (Via Supabase Dashboard - CLI tidak support cron)
   - Buka: https://app.supabase.com/project/batonwnqdwxaxcsjykxw/functions
   - Click function `send-reminder`
   - Tab "Cron Jobs" → Add Cron Job
   - Cron: `* * * * *` (every minute)
   - Method: GET, Path: `/dispatch`
   - Save

5. **Test from App**
   - Open app → TestNotificationScreen
   - Click "Schedule Firebase Reminder (3 menit)"
   - Wait 2-3 min or click "Manual Dispatch"
   - See notification ✅

## 🎯 What You Get

- ✅ Push notifications via Firebase Cloud Messaging
- ✅ Scheduled reminders 5 minutes before event
- ✅ Works offline → Shows when online
- ✅ All notifications persisted & trackable

## 📚 Full Docs

- `FIREBASE_SETUP_CHECKLIST.md` ← Start here
- `FIREBASE_SETUP.md` ← Detailed steps
- `FIREBASE_TESTING.md` ← Troubleshooting
- `README_FIREBASE.md` ← Full overview

## ⚡ Test Command

```bash
# Schedule reminder (2025-12-31T14:30:00Z = 2-3 min from now)
curl -X POST https://YOUR_PROJECT.functions.supabase.co/send-reminder \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "00000000-0000-0000-0000-000000000000",
    "device_token": "AAAA...",
    "title": "Test",
    "body": "Test notification",
    "reminder_at": "2025-12-31T14:30:00Z"
  }'

# Trigger dispatch
curl https://YOUR_PROJECT.functions.supabase.co/send-reminder/dispatch
```

**Done!** 🎉
