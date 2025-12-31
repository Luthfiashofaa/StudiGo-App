-- Table for reminder scheduling
-- Run in Supabase SQL editor or psql
CREATE TABLE IF NOT EXISTS public.reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  device_token text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  reminder_at timestamptz NOT NULL,
  sent boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index to fetch due reminders efficiently
CREATE INDEX IF NOT EXISTS reminders_due_idx
  ON public.reminders (sent, reminder_at);
