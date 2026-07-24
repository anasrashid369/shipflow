# Multi-Tenancy: Row-Level Security Design

## The problem

ShipFlow is a multi-tenant SaaS: many businesses (tenants) share the same database, but each tenant's data must be completely invisible to every other tenant. The naive approach — adding `WHERE tenant_id = ?` to every query — works until someone forgets it. One missing `WHERE` clause in one endpoint, one buggy migration script, one new engineer unfamiliar with the convention, and Tenant A can read Tenant B's inventory, orders, or customer data.

This is a real, common vulnerability class in multi-tenant systems. The fix used here is **Postgres Row-Level Security (RLS)**: isolation enforced by the database itself, not by remembering to write the right `WHERE` clause everywhere.

## How it works

```sql
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON inventory_items
  USING (tenant_id = current_setting('app.current_tenant_id', true));
```

- `ENABLE ROW LEVEL SECURITY` turns on RLS for the table. Once enabled, **no rows are visible by default** — access must be explicitly granted by a policy.
- `CREATE POLICY` defines that rule: a row is only visible/writable if its `tenant_id` matches a session-level setting called `app.current_tenant_id`.
- The application sets that session variable once per request, before running any query:

```javascript
await client.query("SELECT set_config('app.current_tenant_id', $1, false)", [tenantId]);
```

From that point on, **every query on that connection is automatically scoped** — `SELECT * FROM inventory_items` silently becomes "all items belonging to this tenant," with zero application-level filtering logic required.

## Two gotchas that matter (and why they matter)

### 1. `ENABLE` alone isn't enough — you need `FORCE`

By default, RLS policies don't apply to the table's **owner**. If the application connects using the same role that owns the table (a common default), RLS is silently bypassed — the policy exists, the code looks correct, and it still leaks data. `FORCE ROW LEVEL SECURITY` closes this gap for non-superuser owners.

### 2. Superusers bypass RLS unconditionally — `FORCE` can't fix this

This is the more important lesson: **Postgres superusers always see all rows, regardless of `FORCE`.** This is correct, intentional Postgres behavior (superusers are meant to have full access), but it means:

> **The application must never connect to the database as a superuser (e.g., the default `postgres` role).**

This project creates a dedicated, least-privilege `app_user` role with only `SELECT/INSERT/UPDATE/DELETE` on the specific tables it needs — no superuser privileges. This is the actual production-correct pattern: connection-level privilege separation is what makes RLS meaningfully enforceable, not just theoretically correct.

## Attack scenario this design prevents

**Scenario**: A new engineer adds a reporting endpoint and, in a hurry, writes:
```sql
SELECT * FROM inventory_items WHERE stock_level < 10;
```
No `tenant_id` filter — a classic, easy-to-miss mistake.

**Without RLS**: This returns low-stock items across *every tenant* — a real data breach.

**With RLS (as implemented here)**: Because the connection is scoped to `app_user` (non-superuser) and the session's `app.current_tenant_id` is set per-request, this exact query — even with the missing `WHERE` clause — **still only returns the current tenant's rows.** The bug becomes invisible/harmless instead of a breach, because the database enforces the boundary the application code forgot.

## What this doesn't cover (yet)

- The current tenant ID comes from a trusted-but-unverified `X-Tenant-Id` header — a real system would resolve this from a signed JWT/Cognito claim (planned for Phase 5's Lambda authorizer), not a client-supplied header.
- No tests yet verifying RLS behavior automatically (a `testcontainers`-based integration test suite is a natural next addition).