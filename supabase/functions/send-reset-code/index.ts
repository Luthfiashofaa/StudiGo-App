import { serve } from "https://deno.land/std@0.203.0/http/server.ts";

function generateCode() {
  const arr = new Uint32Array(1);
  crypto.getRandomValues(arr);
  const n = arr[0] % 1000000;
  return n.toString().padStart(6, "0");
}

async function sendWithSendGrid(email: string, code: string) {
  const key = Deno.env.get("SENDGRID_API_KEY");
  if (!key) {
    console.warn("SENDGRID_API_KEY not set; skipping send");
    return { ok: false, reason: "no_sendgrid" };
  }

  const payload = {
    personalizations: [{ to: [{ email }] }],
    from: { email: Deno.env.get("RESET_FROM_EMAIL") || "no-reply@yourdomain.com", name: Deno.env.get("RESET_FROM_NAME") || "StudiGo" },
    subject: Deno.env.get("RESET_SUBJECT") || "Kode reset password Anda",
    content: [
      {
        type: "text/plain",
        value: `Kode reset Anda: ${code}\n
Jangan bagikan kode ini kepada siapapun. Kode ini berlaku selama ${Deno.env.get("RESET_CODE_TTL_MINUTES") || "10"} menit.`,
      },
    ],
  };

  const res = await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const text = await res.text();
    console.error("SendGrid error", res.status, text);
    return { ok: false, reason: "sendgrid_error", detail: text };
  }
  return { ok: true };
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "method_not_allowed" }), { status: 405 });
    }

    const ct = req.headers.get("content-type") || "";
    let body: any = {};
    if (ct.includes("application/json")) {
      body = await req.json();
    } else {
      const text = await req.text();
      try {
        const p = new URLSearchParams(text);
        body.email = p.get("email");
      } catch {
        // ignore
      }
    }

    const email = (body?.email) || (body?.name) || (new URL(req.url).searchParams.get("email")) || (new URL(req.url).searchParams.get("name"));

    if (!email || typeof email !== "string") {
      return new Response(JSON.stringify({ error: "email_required" }), { status: 400 });
    }

    const normalized = email.trim().toLowerCase();

    const code = generateCode();

    // Optionally: store the code (hashed) in your DB here using SUPABASE_SERVICE_ROLE_KEY

    const sendResult = await sendWithSendGrid(normalized, code);
    console.log('sendResult', sendResult);
    if (!sendResult.ok && sendResult.reason !== "no_sendgrid") {
      return new Response(JSON.stringify({ error: "email_send_failed", detail: sendResult.detail || null }), { status: 502 });
    }

    const devReturn = (Deno.env.get("DEV_RETURN_CODE") || "false") === "true";

    const resp: Record<string, unknown> = { message: "ok" };
    if (devReturn) {
      resp.dev_code = code;
      resp.send_result = sendResult;
    }

    return new Response(JSON.stringify(resp), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (err) {
    console.error("internal error", err);
    return new Response(JSON.stringify({ error: "internal_error" }), { status: 500 });
  }
});
// end
