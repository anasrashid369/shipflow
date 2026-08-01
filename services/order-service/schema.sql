DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user WITH LOGIN PASSWORD 'app_password';
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  tenant_id VARCHAR(100) NOT NULL,
  sku VARCHAR(100) NOT NULL,
  quantity INTEGER NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'placed',
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON orders
  USING (tenant_id = current_setting('app.current_tenant_id', true));

GRANT SELECT, INSERT, UPDATE ON orders TO app_user;
GRANT USAGE, SELECT ON SEQUENCE orders_id_seq TO app_user;