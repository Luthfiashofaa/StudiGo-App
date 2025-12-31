// Supabase Edge Function: send-reminder
// Handles creation of reminder records and dispatches FCM push notifications
// Requires env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_SERVER_KEY
// Table expected: reminders(id uuid, user_id uuid, device_token text, title text, body text, reminder_at timestamptz, sent boolean default false, created_at timestamptz default now())

import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2?target=deno";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v4.14.4/index.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const fcmProjectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
const fcmClientEmail = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
const rawPrivateKey = Deno.env.get("FCM_PRIVATE_KEY") ?? "";
const fcmPrivateKey = rawPrivateKey.replace(/\\n/g, "\n");

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// Insert new reminder via POST
async function createReminder(request: Request) {
  const payload = await request.json().catch(() => null);
  if (!payload) {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400 });
  }

  const { user_id, device_token, title, body, reminder_at, category } = payload;
  if (!user_id || !device_token || !title || !body || !reminder_at) {
    return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400 });
  }

  try {
    const { data, error } = await supabase
      .from("reminders")
      .insert({ user_id, device_token, title, body, category: category || "Umum", reminder_at })
      .select()
      .single();

    if (error) {
      console.error("[send-reminder] Database error:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    console.log("[send-reminder] Reminder created successfully:", data);
    return new Response(JSON.stringify({ ok: true, reminder: data }), { status: 201 });
  } catch (err) {
    console.error("[send-reminder] Exception in createReminder:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
}

// Send due reminders (intended for scheduled invocation / cron)
async function sendDueReminders() {
  console.log(`[send-reminder] FCM Config check - ProjectId: ${fcmProjectId ? 'SET' : 'MISSING'}, ClientEmail: ${fcmClientEmail ? 'SET' : 'MISSING'}, PrivateKey: ${fcmPrivateKey ? 'SET' : 'MISSING'}`);
  
  if (!fcmProjectId || !fcmClientEmail || !fcmPrivateKey) {
    return {
      status: 500,
      body: { error: "Missing FCM config (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY)" },
    };
  }

  const now = new Date().toISOString();
  const { data, error } = await supabase
    .from("reminders")
    .select("id, device_token, title, body")
    .eq("sent", false)
    .lte("reminder_at", now)
    .limit(100);

  if (error) {
    return { status: 500, body: { error: error.message } };
  }

  for (const row of data ?? []) {
    try {
      await sendFcm(
        row.device_token,
        row.title,
        row.body,
        row.category || "Umum"
      );
      await supabase.from("reminders").update({ sent: true }).eq("id", row.id);
    } catch (err) {
      await supabase.from("reminders").update({ sent: false }).eq("id", row.id);
      console.error("FCM send error", err);
    }
  }

  return { status: 200, body: { sent: data?.length ?? 0 } };
}

// Color codes for categories
function getCategoryColor(category: string): string {
  const colors: Record<string, string> = {
    "Kuliah": "#3B82F6",      // Blue
    "Kerja": "#EF4444",        // Red
    "Olahraga": "#10B981",     // Green
    "Personal": "#8B5CF6",     // Purple
    "Meeting": "#F59E0B",      // Amber
    "Umum": "#6B7280",         // Gray
  };
  return colors[category] || colors["Umum"];
}

async function sendFcm(token: string, title: string, body: string, category: string) {
  const accessToken = await getAccessToken();
  const color = getCategoryColor(category);

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          category: category,
          color: color,
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "reminder_channel",
            color: color,
            sound: "default",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
      },
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`FCM v1 error ${res.status}: ${text}`);
  }
}

async function getAccessToken(): Promise<string> {
  const aud = "https://oauth2.googleapis.com/token";
  const now = Math.floor(Date.now() / 1000);

  const key = await importPKCS8(fcmPrivateKey, "RS256");

  const jwt = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .setIssuer(fcmClientEmail)
    .setSubject(fcmClientEmail)
    .setAudience(aud)
    .sign(key);

  const res = await fetch(aud, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to get access token: ${res.status} ${text}`);
  }

  const json = await res.json();
  const token = json.access_token as string | undefined;
  if (!token) {
    throw new Error("access_token not returned from Google");
  }

  return token;
}

serve(async (req) => {
  const url = new URL(req.url);
  const pathname = url.pathname;
  
  console.log(`[send-reminder] ${req.method} ${pathname}`);

  // Extract the path after /functions/v1/send-reminder
  // pathname will be like: /send-reminder or /send-reminder/dispatch
  const funcPath = pathname.replace('/send-reminder', '') || '/';
  
  // Handle POST / for creating reminders
  if (req.method === "POST" && (funcPath === "/" || funcPath === "")) {
    console.log("[send-reminder] Routing to createReminder");
    return createReminder(req);
  }

  // Handle GET /dispatch for dispatching pending reminders
  if (req.method === "GET" && funcPath.includes("dispatch")) {
    console.log("[send-reminder] Routing to sendDueReminders");
    const result = await sendDueReminders();
    return new Response(JSON.stringify(result.body), { status: result.status });
  }

  console.log(`[send-reminder] Path not matched: ${funcPath}`);
  return new Response(JSON.stringify({ error: "Not found", path: funcPath, fullPath: pathname }), { status: 404 });
});
