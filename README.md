# ShipFlow

A multi-tenant SaaS inventory and order management platform — event-driven microservices on AWS, with row-level tenant isolation, Cognito authentication, and a native mobile client.

## Demo

*(video link here once recorded)*

## Architecture

Mobile App (Flutter)
↓
Application Load Balancer (Cognito hosted-UI authentication)
↓
ECS Fargate: inventory-service
├─→ RDS PostgreSQL (Row-Level Security, tenant-isolated)
└─→ EventBridge (publishes LowStockDetected events)
↓
SQS queue
↓
ECS Fargate: notification-service (polls queue, processes alerts)


## Tech Stack

**Backend**: Node.js/Express microservices on AWS ECS Fargate
**Database**: PostgreSQL (RDS) with Row-Level Security for tenant isolation
**Auth**: AWS Cognito, ALB-native authentication (hosted UI, no API Gateway)
**Events**: EventBridge + SQS for decoupled inter-service communication
**Infra**: Terraform, validated against MiniStack (local AWS emulator) to avoid real cloud cost during development
**Mobile**: Flutter, custom duotone (emerald/violet) design system

## Why These Design Choices

- **ECS Fargate over Lambda**: these are long-running, connection-pooling services — a different workload shape than PulseOps' bursty alert logic, justifying a different compute model.
- **ALB-native Cognito over API Gateway + Lambda authorizer**: the architecture is ALB-fronted from the start; adding API Gateway on top would be a redundant second entry point.
- **Row-Level Security over application-layer filtering**: tenant isolation enforced by the database itself — a forgotten `WHERE tenant_id = ?` clause in application code still can't leak data across tenants. See `docs/multi-tenancy.md` for the full design, including two real RLS bypass gotchas found and fixed during development.
- **EventBridge + SQS over direct HTTP calls**: `inventory-service` has no knowledge that `notification-service` exists — a failure in notification processing can't cascade into inventory operations.

## What I'd Add Next

- Order management service (currently inventory-only)
- Automated integration tests (testcontainers-based, real Postgres in CI)
- Rate limiting per tenant at the ALB layer
- Real AWS deployment validation (currently validated against MiniStack only, given zero-cost constraint — see `docs/` for full reasoning)

## Documentation

- [`docs/multi-tenancy.md`](docs/multi-tenancy.md) — RLS design, two real security gaps found and fixed
- [`docs/event-driven-architecture.md`](docs/event-driven-architecture.md) — EventBridge/SQS design and debugging notes
- [`docs/cognito-auth.md`](docs/cognito-auth.md) — Auth architecture and tenant resolution