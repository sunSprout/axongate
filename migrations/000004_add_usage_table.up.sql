-- Create usage table for tracking token usage and costs
CREATE TABLE IF NOT EXISTS usages (
    id VARCHAR(36) PRIMARY KEY DEFAULT (gen_random_uuid())::varchar,
    request_id VARCHAR(255) NOT NULL UNIQUE,
    user_token_id VARCHAR(36) NOT NULL,
    model_id VARCHAR(36) NOT NULL,
    model_name VARCHAR(255) NOT NULL,
    provider_id VARCHAR(36) NOT NULL,
    provider_token_id VARCHAR(36) NOT NULL,
    input_tokens INTEGER NOT NULL DEFAULT 0 CHECK (input_tokens >= 0),
    output_tokens INTEGER NOT NULL DEFAULT 0 CHECK (output_tokens >= 0),
    input_cost DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (input_cost >= 0),
    output_cost DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (output_cost >= 0),
    total_cost DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (total_cost >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'USD' CHECK (currency IN ('USD', 'CNY')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_usage_request_id ON usages(request_id);
CREATE INDEX idx_usage_user_token_id ON usages(user_token_id);
CREATE INDEX idx_usage_model_id ON usages(model_id);
CREATE INDEX idx_usage_created_at ON usages(created_at);
CREATE INDEX idx_usage_user_token_created ON usages(user_token_id, created_at);
CREATE INDEX idx_usage_provider_token_id ON usages(provider_token_id);
CREATE INDEX idx_usage_provider_token_created ON usages(provider_token_id, created_at);

-- Add comment on table
COMMENT ON TABLE usages IS 'Token usage and cost tracking for each API request';

-- Add comments on columns
COMMENT ON COLUMN usages.request_id IS 'Unique request ID for deduplication';
COMMENT ON COLUMN usages.user_token_id IS 'Reference to user token';
COMMENT ON COLUMN usages.model_id IS 'Reference to model used';
COMMENT ON COLUMN usages.model_name IS 'Model name (denormalized for performance)';
COMMENT ON COLUMN usages.provider_id IS 'Reference to provider';
COMMENT ON COLUMN usages.provider_token_id IS 'Reference to provider token used for the request';
COMMENT ON COLUMN usages.input_tokens IS 'Number of input tokens';
COMMENT ON COLUMN usages.output_tokens IS 'Number of output tokens';
COMMENT ON COLUMN usages.input_cost IS 'Cost for input tokens';
COMMENT ON COLUMN usages.output_cost IS 'Cost for output tokens';
COMMENT ON COLUMN usages.total_cost IS 'Total cost (input_cost + output_cost)';
COMMENT ON COLUMN usages.currency IS 'Currency for cost calculation';
COMMENT ON COLUMN usages.created_at IS 'Request timestamp';