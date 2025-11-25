// Deno Supabase Edge Function: verify-reset-code
// POST { email, code, new_password }
// Verifies code from password_reset_codes, checks expiry, updates Supabase user password via admin API, and deletes codes.

// @ts-nocheck

declare const Deno: any;

import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const CODE_SALT = Deno.env.get('CODE_SALT') || 'change-me';

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

serve(async (req: any) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  try {
    const { email, code, new_password } = await req.json();
    if (!email || !code || !new_password) return new Response('Missing fields', { status: 400 });

    // find latest code for this email
    const { data, error } = await supabaseAdmin
      .from('password_reset_codes')
      .select('*')
      .eq('email', email)
      .order('created_at', { ascending: false })
      .limit(1);

    if (error) {
      console.error('db lookup error', error);
      return new Response('Internal error', { status: 500 });
    }

    if (!data || data.length === 0) return new Response('Invalid code', { status: 400 });

    const row = data[0];
    const expectedHash = await sha256Hex(code + CODE_SALT);

    if (row.code_hash !== expectedHash) return new Response('Invalid code', { status: 400 });

    if (new Date(row.expires_at) < new Date()) return new Response('Code expired', { status: 400 });

    // find user by email via admin endpoint
    const usersRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?email=${encodeURIComponent(email)}`, {
      headers: {
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE}`,
        apikey: SUPABASE_SERVICE_ROLE,
      }
    });
    if (!usersRes.ok) {
      console.error('user lookup failed', await usersRes.text());
      return new Response('User lookup failed', { status: 500 });
    }
    const users = await usersRes.json();
    const userId = users?.[0]?.id;
    if (!userId) return new Response('User not found', { status: 404 });

    // update user password via admin endpoint
    const updateRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE}`,
        apikey: SUPABASE_SERVICE_ROLE,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ password: new_password }),
    });

    if (!updateRes.ok) {
      console.error('update user error', await updateRes.text());
      return new Response('Failed to update password', { status: 500 });
    }

    // cleanup code rows for this email
    await supabaseAdmin.from('password_reset_codes').delete().eq('email', email);

    return new Response(JSON.stringify({ success: true }), { headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    console.error(err);
    return new Response('Server error', { status: 500 });
  }
});

async function sha256Hex(msg: string) {
  const enc = new TextEncoder().encode(msg);
  const hash = await crypto.subtle.digest('SHA-256', enc);
  return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
}
