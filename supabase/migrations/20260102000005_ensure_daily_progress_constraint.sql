-- Ensure daily_progress has explicit constraint name for upsert
-- Drop existing constraint and recreate with explicit name

ALTER TABLE daily_progress
DROP CONSTRAINT IF EXISTS daily_progress_user_id_date_key CASCADE;

ALTER TABLE daily_progress
ADD CONSTRAINT daily_progress_uq UNIQUE(user_id, date);
