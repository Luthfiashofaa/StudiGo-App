// Deno Supabase Edge Function: send-reset-code
// POST { email }
// Creates a numeric code (6 digits), stores its SHA-256 hash in `password_reset_codes` table,
// and sends the code via SendGrid. Does not reveal whether the email exists (generic response).

// @ts-nocheck

declare const Deno: any;

import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')!;
const CODE_SALT = Deno.env.get('CODE_SALT') || 'change-me';
const MAX_PER_HOUR = Number(Deno.env.get('RESET_MAX_PER_HOUR') || '5');

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

serve(async (req: any) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  try {
    const { email } = await req.json();
    if (!email || typeof email !== 'string') return new Response('Missing email', { status: 400 });

    const now = new Date();

    // Look up user in public.users (do NOT expose existence to client)
    const { data: users, error: userErr } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', email)
      .limit(1);

    if (userErr) {
      console.error('user lookup failed', userErr);
      // respond generically for safety
      return jsonResponse({ success: true });
    }

    if (!users || users.length === 0) {
      // Do not reveal whether the email exists. Return success so client cannot enumerate.
      return jsonResponse({ success: true });
    }

    // Rate-limit: count codes created in the last hour for this email
    const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { data: recent, error: recentErr } = await supabaseAdmin
      .from('password_reset_codes')
      .select('id', { count: 'exact' })
      .eq('email', email)
      .gte('created_at', since);

    if (recentErr) console.error('recent lookup err', recentErr);

    const count = Array.isArray(recent) ? recent.length : 0;
    if (count >= MAX_PER_HOUR) {
      console.warn(`rate limit exceeded for ${email}`);
      // Generic success to caller; don't send email
      return jsonResponse({ success: true });
    }

    // remove any previous codes for this email (optional: keep audit if desired)
    const delRes = await supabaseAdmin.from('password_reset_codes').delete().eq('email', email);
    if (delRes.error) console.error('cleanup error', delRes.error);

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 15 * 60_000); // 15 minutes
    const codeHash = await sha256Hex(code + CODE_SALT);

    const { error: insertErr } = await supabaseAdmin.from('password_reset_codes').insert({
      email,
      code_hash: codeHash,
      expires_at: expires.toISOString(),
    });

    if (insertErr) {
      console.error('insert error', insertErr);
      return jsonResponse({ success: true });
    }

    // Send email via SendGrid (text-only). If send fails, we keep DB row for audit but log error.
    if (!SENDGRID_API_KEY) {
      console.error('SENDGRID_API_KEY not set');
      // For development, optionally return the code in the response if enabled.
      if (Deno.env.get('DEV_RETURN_CODE') === 'true') return jsonResponse({ success: true, code });
      return jsonResponse({ success: true });
    }

    const mail = {
      personalizations: [{ to: [{ email }], subject: 'Kode Reset Password Anda' }],
      from: { email: 'no-reply@studigo.app', name: 'StudiGo' },
      content: [
        {
          type: 'text/plain',
          value: `Kode untuk mereset password Anda: ${code}\n\nKode ini berlaku 15 menit. Jangan bagikan kode ini kepada siapapun.`,
        },
      ],
    };

    const sendRes = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${SENDGRID_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(mail),
    });

    if (!sendRes.ok) {
      const body = await sendRes.text();
      console.error('sendgrid error', body);
      // keep DB row; return generic success
      // For development, optionally return code to help testing email flow.
      if (Deno.env.get('DEV_RETURN_CODE') === 'true') return jsonResponse({ success: true, code, sendgrid_error: body });
      return jsonResponse({ success: true });
    }

    // success
    if (Deno.env.get('DEV_RETURN_CODE') === 'true') {
      // In dev mode return the code in response to ease testing (DO NOT enable in production)
      return jsonResponse({ success: true, code });
    }

    return jsonResponse({ success: true });
  } catch (err) {
    console.error(err);
    return new Response('Server error', { status: 500 });
  }
});

function jsonResponse(obj: any) {
  return new Response(JSON.stringify(obj), { headers: { 'Content-Type': 'application/json' } });
}

async function sha256Hex(msg: string) {
  const enc = new TextEncoder().encode(msg);
  const hash = await crypto.subtle.digest('SHA-256', enc);
  return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
}
