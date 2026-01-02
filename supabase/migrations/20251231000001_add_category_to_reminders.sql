-- Add category column to reminders table
ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'Umum';

-- Add comment for clarity
COMMENT ON COLUMN public.reminders.category IS 'Schedule category (Kuliah, Kerja, Olahraga, Personal, Meeting, Umum)';
