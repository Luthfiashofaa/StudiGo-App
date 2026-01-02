-- Add missing columns to daily_progress table
-- This migration adds columns that were missing from the original schema

ALTER TABLE IF EXISTS daily_progress 
ADD COLUMN IF NOT EXISTS progress_percentage DOUBLE PRECISION DEFAULT 0;

ALTER TABLE IF EXISTS daily_progress 
ADD COLUMN IF NOT EXISTS completed_tasks INTEGER DEFAULT 0;
