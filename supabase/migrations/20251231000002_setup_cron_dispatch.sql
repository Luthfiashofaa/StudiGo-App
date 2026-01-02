-- Setup pg_cron for automatic reminder dispatch
-- This will call the dispatch edge function every minute

-- Enable pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant necessary permissions to postgres role
GRANT USAGE ON SCHEMA cron TO postgres;

-- Remove any existing cron job with the same name
SELECT cron.unschedule('dispatch-reminders-every-minute') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'dispatch-reminders-every-minute'
);

-- Create cron job to call dispatch endpoint every minute using pg_net
-- pg_net is pre-installed in Supabase and works reliably
SELECT cron.schedule(
  'dispatch-reminders-every-minute',
  '* * * * *',
  $$
  SELECT
    net.http_post(
      url:='https://batonwnqdwxaxcsjykxw.supabase.co/functions/v1/dispatch-reminders-cron',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhdG9ud25xZHd4YXhzY2p5a3ciLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzM0NTU1MjAwLCJleHAiOjE4OTczMDk2MDB9.x4RG0Ay-XfM8eZEqQFXB2FRqVGiZNu2WjLfKAVxpJds"}'::jsonb,
      body:='{}'::jsonb
    ) as request_id;
  $$
);

-- Verify cron job was created
SELECT jobid, schedule, command, nodename, active 
FROM cron.job 
WHERE jobname = 'dispatch-reminders-every-minute';
