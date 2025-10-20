-- 为 provider_tokens 表添加 active 字段
ALTER TABLE provider_tokens 
ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;

-- 创建索引以优化查询性能
CREATE INDEX IF NOT EXISTS idx_provider_tokens_active ON provider_tokens(provider_id, active);

-- 添加注释
COMMENT ON COLUMN provider_tokens.active IS 'Token是否激活，false表示已被禁用';