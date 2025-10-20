-- 回滚顺序需先删依赖表
DROP TABLE IF EXISTS models;
DROP TABLE IF EXISTS provider_tokens;
DROP TABLE IF EXISTS providers;
DROP TABLE IF EXISTS user_tokens;
DROP TABLE IF EXISTS casbin_rules;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;
