DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user WITH LOGIN PASSWORD 'app_password';
  END IF;
END
$$;

GRANT CONNECT ON DATABASE shipflow TO app_user;
CREATE TABLE IF NOT EXISTS inventory_items (
  id SERIAL PRIMARY KEY,
  tenant_id VARCHAR(100) NOT NULL,
  sku VARCHAR(100) NOT NULL,
  name VARCHAR(255) NOT NULL,
  stock_level INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable row-level security on this table
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Policy: a query can only see/modify rows where tenant_id matches
-- the current session's tenant context (set per-request by the app)
CREATE POLICY tenant_isolation_policy ON inventory_items
  USING (tenant_id = current_setting('app.current_tenant_id', true));
  GRANT SELECT, INSERT, UPDATE, DELETE ON inventory_items TO app_user;
GRANT USAGE, SELECT ON SEQUENCE inventory_items_id_seq TO app_user;