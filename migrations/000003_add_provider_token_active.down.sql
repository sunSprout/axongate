-- 回滚：删除 active 字段和相关索引
DROP INDEX IF EXISTS idx_provider_tokens_active;
ALTER TABLE provider_tokens DROP COLUMN IF EXISTS active;