-- Remove indexes
DROP INDEX IF EXISTS idx_usage_day_user_token;
DROP INDEX IF EXISTS idx_usage_day_model;
DROP INDEX IF EXISTS idx_usage_day;

-- Remove day column
ALTER TABLE usages DROP COLUMN IF EXISTS day;