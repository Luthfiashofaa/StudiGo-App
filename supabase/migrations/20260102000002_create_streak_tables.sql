-- Create user_streaks table to store streak data
CREATE TABLE IF NOT EXISTS user_streaks (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_completed_date TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create daily_progress table to track daily progress (0-100%)
CREATE TABLE IF NOT EXISTS daily_progress (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  progress_percentage DOUBLE PRECISION NOT NULL DEFAULT 0,
  completed_tasks INTEGER NOT NULL DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, date)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id ON user_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_user_id ON daily_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_date ON daily_progress(date);

-- Enable RLS for security
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_streaks
CREATE POLICY "Users can view their own streak" ON user_streaks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own streak" ON user_streaks
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own streak" ON user_streaks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for daily_progress
CREATE POLICY "Users can view their own progress" ON daily_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" ON daily_progress
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress" ON daily_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Add completed_tasks column if not exists (for existing tables)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'daily_progress' 
    AND column_name = 'completed_tasks'
  ) THEN
    ALTER TABLE daily_progress ADD COLUMN completed_tasks INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;
