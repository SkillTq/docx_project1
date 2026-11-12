-- Test data seeder for DataBaseCode.sql (PostgreSQL)
-- Adds well over 1,000 related rows. Does not delete existing data.
-- Run after creating the schema in DataBaseCode.sql.
-- All generated accounts/keys are synthetic; password_hash values are placeholders.

BEGIN;

-- 1) Reference data
INSERT INTO roles (name)
VALUES ('admin'), ('user'), ('manager')
ON CONFLICT (name) DO NOTHING;

INSERT INTO permissions (name)
VALUES
  ('users.read'), ('users.write'),
  ('applications.read'), ('applications.write'),
  ('orders.read'), ('orders.write'),
  ('keys.read'), ('keys.write'),
  ('payments.read'), ('payments.write')
ON CONFLICT (name) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE
  (r.name = 'admin')
  OR (r.name = 'manager' AND p.name IN (
    'applications.read', 'applications.write',
    'orders.read', 'orders.write', 'keys.read', 'keys.write',
    'payments.read'
  ))
  OR (r.name = 'user' AND p.name IN (
    'applications.read', 'orders.read', 'keys.read'
  ))
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 2) 1,200 synthetic users
INSERT INTO users (role_id, username, email, password_hash, created_at)
SELECT
  (SELECT id FROM roles WHERE name = 'user' LIMIT 1),
  'seed_user_' || lpad(g.n::text, 5, '0'),
  'seed_user_' || lpad(g.n::text, 5, '0') || '@example.test',
  'TEST_ONLY_NOT_A_REAL_PASSWORD_HASH',
  now() - (g.n || ' minutes')::interval
FROM generate_series(1, 1200) AS g(n)
ON CONFLICT (username) DO NOTHING;

-- 3) 30 applications, owned by seeded users
INSERT INTO applications
  (title, description, image_url, is_active, created_by_user_id, created_at, updated_at)
SELECT
  'Seed Application ' || lpad(g.n::text, 3, '0'),
  'Synthetic test application #' || g.n,
  'https://example.test/images/app-' || g.n || '.png',
  (g.n % 7 <> 0),
  (SELECT u.id FROM users u
   WHERE u.username = 'seed_user_' || lpad(g.n::text, 5, '0')),
  now() - (g.n || ' days')::interval,
  now()
FROM generate_series(1, 30) AS g(n)
ON CONFLICT DO NOTHING;

-- 4) Three plans per seeded application (90 plans total)
INSERT INTO applications_plans
  (application_id, name, duration_days, price, is_active, created_at, updated_at)
SELECT
  a.id,
  v.plan_name,
  v.days,
  v.price,
  true,
  now(),
  now()
FROM applications a
CROSS JOIN (VALUES
  ('Basic 30 days', 30, 4.99::numeric),
  ('Standard 90 days', 90, 11.99::numeric),
  ('Premium 365 days', 365, 39.99::numeric)
) AS v(plan_name, days, price)
WHERE a.title LIKE 'Seed Application %'
ON CONFLICT (application_id, duration_days) DO NOTHING;

-- 5) 1,200 unique test keys distributed over the seeded plans
INSERT INTO "keys"
  (key_code, plan_id, status, created_by_user_id, created_at)
SELECT
  'TEST-KEY-' || lpad(g.n::text, 6, '0'),
  p.id,
  CASE
    WHEN g.n % 20 = 0 THEN 'revoked'
    WHEN g.n % 5 = 0 THEN 'sold'
    WHEN g.n % 7 = 0 THEN 'reserved'
    ELSE 'available'
  END,
  (SELECT u.id FROM users u
   WHERE u.username = 'seed_user_' || lpad(((g.n - 1) % 1200 + 1)::text, 5, '0')),
  now() - (g.n || ' minutes')::interval
FROM generate_series(1, 1200) AS g(n)
JOIN applications_plans p
  ON p.application_id = (
    SELECT a.id
    FROM applications a
    WHERE a.title = 'Seed Application ' || lpad((((g.n - 1) % 30) + 1)::text, 3, '0')
  )
 AND p.duration_days = CASE ((g.n - 1) % 3)
   WHEN 0 THEN 30
   WHEN 1 THEN 90
   ELSE 365
 END
ON CONFLICT (key_code) DO NOTHING;

-- 6) 1,200 orders. Statuses are synthetic and do not represent real transactions.
INSERT INTO orders (user_id, status, total_amount, created_at, updated_at)
SELECT
  (SELECT u.id FROM users u
   WHERE u.username = 'seed_user_' || lpad(g.n::text, 5, '0')),
  CASE
    WHEN g.n % 10 = 0 THEN 'cancelled'
    WHEN g.n % 4 = 0 THEN 'completed'
    WHEN g.n % 4 = 1 THEN 'paid'
    WHEN g.n % 4 = 2 THEN 'pending_payment'
    ELSE 'processing'
  END,
  CASE ((g.n - 1) % 3)
    WHEN 0 THEN 4.99
    WHEN 1 THEN 11.99
    ELSE 39.99
  END,
  now() - (g.n || ' minutes')::interval,
  now()
FROM generate_series(1, 1200) AS g(n);

-- 7) One order item per seeded order, linked to a matching plan and key
INSERT INTO order_items
  (order_id, plan_id, key_id, plan_name, duration_days, price, created_at)
SELECT
  o.id,
  p.id,
  k.id,
  p.name,
  p.duration_days,
  p.price,
  o.created_at
FROM generate_series(1, 1200) AS g(n)
JOIN orders o
  ON o.user_id = (
    SELECT u.id FROM users u
    WHERE u.username = 'seed_user_' || lpad(g.n::text, 5, '0')
  )
 AND o.created_at = now() - (g.n || ' minutes')::interval
JOIN "keys" k
  ON k.key_code = 'TEST-KEY-' || lpad(g.n::text, 6, '0')
JOIN applications_plans p ON p.id = k.plan_id
ON CONFLICT (key_id) DO NOTHING;

-- 8) Payments for the seeded orders (synthetic provider IDs)
INSERT INTO payments
  (order_id, provider, provider_payment_id, amount, status, created_at, paid_at)
SELECT
  o.id,
  'test_provider',
  'TEST-PAY-' || lpad(g.n::text, 6, '0'),
  o.total_amount,
  CASE
    WHEN g.n % 10 = 0 THEN 'failed'
    WHEN g.n % 4 = 2 THEN 'pending'
    ELSE 'succeeded'
  END,
  o.created_at,
  CASE WHEN g.n % 10 = 0 OR g.n % 4 = 2
       THEN NULL ELSE o.created_at + interval '2 minutes' END
FROM generate_series(1, 1200) AS g(n)
JOIN users u
  ON u.username = 'seed_user_' || lpad(g.n::text, 5, '0')
JOIN orders o
  ON o.user_id = u.id
 AND o.created_at = now() - (g.n || ' minutes')::interval
ON CONFLICT (provider_payment_id) DO NOTHING;

-- 9) 300 activations for the first 300 test keys
-- Only keys with a sold status are activated; the generated key statuses above
-- guarantee some sold keys, but if a key is not sold it is skipped.
INSERT INTO activations
  (key_id, user_id, hwid, activated_at, expires_at, deactivated_at)
SELECT
  k.id,
  (SELECT u.id FROM users u
   WHERE u.username = 'seed_user_' || lpad(g.n::text, 5, '0')),
  'TEST-HWID-' || lpad(g.n::text, 6, '0'),
  now() - interval '1 day',
  now() + interval '29 days',
  NULL
FROM generate_series(1, 1200) AS g(n)
JOIN "keys" k
  ON k.key_code = 'TEST-KEY-' || lpad(g.n::text, 6, '0')
WHERE k.status = 'sold'
  AND g.n <= 300
ON CONFLICT (key_id) DO NOTHING;

COMMIT;

-- 10) Quick row-count report for the seeded tables
SELECT 'roles' AS table_name, count(*) AS rows FROM roles
UNION ALL SELECT 'permissions', count(*) FROM permissions
UNION ALL SELECT 'users', count(*) FROM users WHERE username LIKE 'seed_user_%'
UNION ALL SELECT 'applications', count(*) FROM applications WHERE title LIKE 'Seed Application %'
UNION ALL SELECT 'applications_plans', count(*) FROM applications_plans ap
  JOIN applications a ON a.id = ap.application_id WHERE a.title LIKE 'Seed Application %'
UNION ALL SELECT 'keys', count(*) FROM "keys" WHERE key_code LIKE 'TEST-KEY-%'
UNION ALL SELECT 'orders', count(*) FROM orders o JOIN users u ON u.id = o.user_id
  WHERE u.username LIKE 'seed_user_%'
UNION ALL SELECT 'order_items', count(*) FROM order_items oi
  JOIN "keys" k ON k.id = oi.key_id WHERE k.key_code LIKE 'TEST-KEY-%'
UNION ALL SELECT 'payments', count(*) FROM payments WHERE provider_payment_id LIKE 'TEST-PAY-%'
UNION ALL SELECT 'activations', count(*) FROM activations WHERE hwid LIKE 'TEST-HWID-%'
ORDER BY table_name;
