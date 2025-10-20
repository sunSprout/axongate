-- Add day column to usages table for efficient daily statistics
ALTER TABLE usages ADD COLUMN IF NOT EXISTS day DATE;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_usage_day ON usages(day);
CREATE INDEX IF NOT EXISTS idx_usage_day_model ON usages(day, model_name);
CREATE INDEX IF NOT EXISTS idx_usage_day_user_token ON usages(day, user_token_id);

-- Add comment on column
COMMENT ON COLUMN usages.day IS 'Date for daily grouping and statistics (server time)';