-- Create reminders table for Firebase notification scheduling
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

-- Grant permissions
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to access only their own reminders
DROP POLICY IF EXISTS "Users can view their own reminders" ON public.reminders;
CREATE POLICY "Users can view their own reminders"
  ON public.reminders
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anon/Service can insert reminders" ON public.reminders;
CREATE POLICY "Anon/Service can insert reminders"
  ON public.reminders
  FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Service role can update sent status" ON public.reminders;
CREATE POLICY "Service role can update sent status"
  ON public.reminders
  FOR UPDATE
  USING (true)
  WITH CHECK (true);
