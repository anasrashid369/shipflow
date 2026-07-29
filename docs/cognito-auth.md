# Phase 5: Cognito Authentication & Tenant Resolution

## Architecture decision: ALB-native Cognito, not API Gateway

The original reference design assumed API Gateway + a Lambda authorizer. ShipFlow's actual architecture (Phase 2) uses an Application Load Balancer in front of ECS Fargate, not API Gateway — adding API Gateway now would mean a redundant second entry point in front of an ALB that already exists.

Instead, this uses **ALB's native Cognito integration**: the listener's `authenticate-cognito` action validates the user's session against the Cognito hosted UI before ever forwarding the request to the container. This is the architecturally correct pattern for an ALB-fronted service, and AWS built it for exactly this use case.

## How tenant resolution works

When ALB authenticates a user, it injects a signed JWT into the `x-amzn-oidc-data` request header containing the user's Cognito claims — including a custom `tenant_id` attribute set on the User Pool. `inventory-service` decodes this header and uses the claim as the authoritative tenant identity:

```javascript
function extractTenantFromAlbHeader(req) {
  const oidcData = req.header("x-amzn-oidc-data");
  if (!oidcData) return null;
  const payloadBase64 = oidcData.split(".")[1];
  const payload = JSON.parse(Buffer.from(payloadBase64, "base64").toString("utf8"));
  return payload["custom:tenant_id"] || null;
}
```

A client-supplied `X-Tenant-Id` header remains as a **fallback only**, used for local development and direct-to-container testing (bypassing the ALB). In a real production deployment, this fallback would be removed — trusting a client-supplied header for tenant identity would defeat the entire point of RLS.

## What's verified vs. what's architecturally correct but untested

**Verified end-to-end**:
- Cognito User Pool + Client created with custom `tenant_id` schema attribute
- Real user creation and password management via Cognito Admin APIs
- Full password-grant authentication flow — genuine JWTs issued and validated (`initiate-auth`)
- RLS enforcement on the actual deployed RDS instance, using a non-superuser `app_user` role (closing the same superuser-bypass gap documented in `multi-tenancy.md`, this time on the real deployed database rather than just local dev)

**Architecturally correct, not fully testable in this environment**:
- ALB's browser-based OAuth redirect flow (`authenticate-cognito` listener action) — Terraform applies successfully and the resource configuration matches AWS's documented pattern, but MiniStack's light edition does not appear to fully simulate the browser-redirect / session-cookie mechanics this feature relies on. A real AWS deployment would need to be tested with an actual browser session to confirm the end-to-end redirect → login → callback → forward flow.

## A second RLS gap found and fixed during this phase

Testing this phase surfaced that the RDS instance deployed in Phase 2 had never received the Phase 3 tenant isolation schema — it was still running the original pre-RLS schema and connecting as the `postgres` superuser (which unconditionally bypasses RLS, as documented in `multi-tenancy.md`). This meant the *deployed* environment was not actually tenant-isolated, despite RLS being fully verified locally.

Fixed by: creating the `app_user` role on the deployed RDS instance, granting it least-privilege access, applying the current schema (tenant_id column + RLS policy), and updating the ECS task definition to connect as `app_user` instead of `postgres`.

**Lesson**: verifying a security control locally is necessary but not sufficient — the same verification needs to be repeated against every environment it's deployed to, since infrastructure and application code can drift independently.