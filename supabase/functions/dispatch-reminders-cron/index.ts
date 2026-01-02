// Supabase Edge Function: dispatch-reminders-cron
// Auto-dispatch pending reminders every minute via cron job
// Call: GET https://YOUR_PROJECT.supabase.co/functions/v1/dispatch-reminders-cron

import { serve } from "https://deno.land/std@0.210.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  console.log("[Cron] Dispatching reminders at:", new Date().toISOString());

  try {
    // Call send-reminder/dispatch endpoint
    const response = await fetch(`${SUPABASE_URL}/functions/v1/send-reminder/dispatch`, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`,
        "Content-Type": "application/json",
      },
    });

    const result = await response.json();
    
    console.log(`[Cron] Dispatch completed. Status: ${response.status}`);
    console.log(`[Cron] Result:`, result);

    return new Response(
      JSON.stringify({ 
        ok: true, 
        timestamp: new Date().toISOString(),
        result 
      }),
      { 
        status: 200, 
        headers: { "Content-Type": "application/json" } 
      }
    );
  } catch (err) {
    console.error("[Cron] Error:", err);
    return new Response(
      JSON.stringify({ 
        error: String(err),
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { "Content-Type": "application/json" } 
      }
    );
  }
});
