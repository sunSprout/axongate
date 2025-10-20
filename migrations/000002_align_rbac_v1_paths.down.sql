-- Revert v1-aligned RBAC policies inserted by 000002

DELETE FROM casbin_rules WHERE p_type='p' AND v0='admin' AND v1='/api/v1/*' AND v2='*';

DELETE FROM casbin_rules WHERE p_type='p' AND v0='user' AND v1 IN (
  '/api/v1/auth/me', '/api/v1/permissions/ui', '/api/v1/permissions/menus'
) AND v2='GET';

DELETE FROM casbin_rules WHERE p_type='p' AND v0='manager' AND v1 IN (
  '/api/v1/users', '/api/v1/user-tokens*', '/api/v1/provider-tokens*', '/api/v1/providers*', '/api/v1/ai-models*'
);

