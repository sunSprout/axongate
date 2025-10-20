-- Align RBAC policies to /api/v1 paths and add baseline permissions

-- Admin: ensure full access to /api/v1
INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'admin', '/api/v1/*', '*'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='admin' AND v1='/api/v1/*' AND v2='*'
);

-- User: minimal read permissions after login
INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'user', '/api/v1/auth/me', 'GET'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='user' AND v1='/api/v1/auth/me' AND v2='GET'
);

INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'user', '/api/v1/permissions/ui', 'GET'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='user' AND v1='/api/v1/permissions/ui' AND v2='GET'
);

INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'user', '/api/v1/permissions/menus', 'GET'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='user' AND v1='/api/v1/permissions/menus' AND v2='GET'
);

-- Manager: typical management resources (adjust as needed)
INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'manager', '/api/v1/users', 'GET'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='manager' AND v1='/api/v1/users' AND v2='GET'
);

INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'manager', '/api/v1/user-tokens*', '*'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='manager' AND v1='/api/v1/user-tokens*' AND v2='*'
);

INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'manager', '/api/v1/provider-tokens*', '*'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='manager' AND v1='/api/v1/provider-tokens*' AND v2='*'
);

INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'manager', '/api/v1/providers*', '*'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='manager' AND v1='/api/v1/providers*' AND v2='*'
);

INSERT INTO casbin_rules (ptype, v0, v1, v2)
SELECT 'p', 'manager', '/api/v1/ai-models*', '*'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rules WHERE ptype='p' AND v0='manager' AND v1='/api/v1/ai-models*' AND v2='*'
);

-- Optionally remove old non-v1 example manager policies to reduce confusion
DELETE FROM casbin_rules WHERE ptype='p' AND v0='manager' AND v1 IN ('/api/users', '/api/tokens');

