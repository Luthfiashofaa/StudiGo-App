# Server functions: password reset

This folder contains two Deno-based Supabase Edge Function examples:

- `send-reset-code.ts` — POST { email }
  - Checks if a user exists in `public.users`.
  - Applies a simple rate-limit (MAX_PER_HOUR).
  - Creates a 6-digit code, stores SHA-256(code + CODE_SALT) in `password_reset_codes` with expiry.
  - Sends the code by email via SendGrid (text-only).
  - Returns a generic success response to avoid user enumeration.

- `verify-reset-code.ts` — POST { email, code, new_password }
  - Verifies the provided code against the latest `password_reset_codes` row for the email.
  - Checks expiry.
  - Updates the Supabase user's password using the Admin API and deletes the used codes.

Required environment variables (set in the function/host environment):

- SUPABASE_URL - your Supabase project URL (https://xyz.supabase.co)
- SUPABASE_SERVICE_ROLE_KEY - your service_role key (keep secret, server-side only)
- SENDGRID_API_KEY - API key to send emails (or replace sending logic)
- CODE_SALT - secret salt appended to codes before hashing (change from default)
- RESET_MAX_PER_HOUR - optional (default 5) rate limit per email per hour

Deploying to Supabase Functions
1. Install and login supabase CLI: `supabase login`
2. Deploy functions:
   supabase functions deploy send-reset-code --project-ref <ref>
   supabase functions deploy verify-reset-code --project-ref <ref>

Testing with curl
- Send code (note: function returns generic success):
  curl -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com"}' https://<your-fn>/send-reset-code

- Verify and reset password:
  curl -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com","code":"123456","new_password":"newpass"}' https://<your-fn>/verify-reset-code

Security notes
- Keep `SUPABASE_SERVICE_ROLE_KEY` secret. Do not ship to client.
- Consider stronger hashing (HMAC/bcrypt) for codes if required.
- Add logging, monitoring, and stricter rate-limiting for production.
