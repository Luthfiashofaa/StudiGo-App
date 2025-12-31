-- Quick Verification: Check if cron is working
-- Run this in Supabase SQL Editor after 5 minutes of setup

-- 1. Check cron job exists and is active
SELECT 
  '✅ Cron Job Status' as check_name,
  CASE 
    WHEN COUNT(*) > 0 AND bool_and(active) THEN '✓ Active'
    WHEN COUNT(*) > 0 THEN '⚠️ Exists but Inactive'
    ELSE '✗ Not Found'
  END as status
FROM cron.job 
WHERE jobname = 'dispatch-reminders-every-minute';

-- 2. Check recent executions (last 5 minutes)
SELECT 
  '📊 Recent Executions' as check_name,
  COUNT(*) as executions_last_5min
FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'dispatch-reminders-every-minute')
AND start_time > NOW() - INTERVAL '5 minutes';

-- 3. Check for any errors
SELECT 
  '❌ Recent Errors' as check_name,
  COUNT(*) as error_count
FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'dispatch-reminders-every-minute')
AND status = 'failed'
AND start_time > NOW() - INTERVAL '5 minutes';

-- 4. Check reminder dispatch stats
SELECT 
  '📬 Reminders Status' as check_name,
  COUNT(*) FILTER (WHERE sent = false AND reminder_at <= NOW()) as pending_due,
  COUNT(*) FILTER (WHERE sent = true AND created_at > NOW() - INTERVAL '1 hour') as sent_last_hour,
  COUNT(*) FILTER (WHERE sent = false AND reminder_at > NOW()) as pending_future
FROM reminders;

-- 5. Show last cron execution details
SELECT 
  '🔍 Last Execution Details' as info,
  start_time AT TIME ZONE 'Asia/Jakarta' as time_wib,
  status,
  return_message
FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'dispatch-reminders-every-minute')
ORDER BY start_time DESC 
LIMIT 1;

-- Expected Results:
-- ✅ Cron Job Status: Active
-- 📊 Recent Executions: 4-5 (one per minute)
-- ❌ Recent Errors: 0
-- 📬 Reminders: pending_due=0, sent_last_hour>0
-- 🔍 Last Execution: status='succeeded', recent time
