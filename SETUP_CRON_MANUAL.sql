-- Manual Setup for Supabase pg_cron
-- Run this SQL in Supabase SQL Editor: https://supabase.com/dashboard/project/batonwnqdwxaxcsjykxw/sql

-- Step 1: Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Step 2: Remove existing cron job if any
SELECT cron.unschedule('dispatch-reminders-every-minute');

-- Step 3: Create cron job to call dispatch edge function every minute
SELECT cron.schedule(
  'dispatch-reminders-every-minute',
  '* * * * *',  -- Every minute
  $$
  SELECT
    net.http_post(
      url:='https://batonwnqdwxaxcsjykxw.supabase.co/functions/v1/dispatch-reminders-cron',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhdG9ud25xZHd4YXhzY2p5a3ciLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzM0NTU1MjAwLCJleHAiOjE4OTczMDk2MDB9.x4RG0Ay-XfM8eZEqQFXB2FRqVGiZNu2WjLfKAVxpJds"}'::jsonb,
      body:='{}'::jsonb
    ) as request_id;
  $$
);

-- Step 4: Verify cron job was created successfully
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job 
WHERE jobname = 'dispatch-reminders-every-minute';

-- Expected output:
-- jobid | jobname                           | schedule   | active | command
-- ------|-----------------------------------|------------|--------|----------
-- 1     | dispatch-reminders-every-minute  | * * * * *  | t      | SELECT net.http_post...

-- To check cron execution history:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
