# ShipFlow

A multi-tenant SaaS inventory and order management platform — event-driven microservices on AWS, with row-level tenant isolation, Cognito authentication, and a native mobile client.

## Demo

*(video link here once recorded)*

## Architecture

Mobile App (Flutter)
↓
Application Load Balancer (Cognito hosted-UI authentication)
↓
┌──────────────────────┐ ┌──────────────────────┐
│ inventory-service │◄───────│ order-service │
│ (ECS Fargate) │ HTTP │ (ECS Fargate) │
└──────────┬────────────┘ └──────────┬────────────┘
│ │
▼ ▼
RDS PostgreSQL (Row-Level Security, tenant-isolated)
• inventory_items table • orders table
│
▼ (on low stock)
EventBridge → SQS queue
▼
notification-service (ECS Fargate, polls queue, logs alerts)


## Tech Stack

**Backend**: Node.js/Express — three independently deployed microservices on AWS ECS Fargate
**Database**: PostgreSQL (RDS) with Row-Level Security for tenant isolation
**Auth**: AWS Cognito, ALB-native authentication (hosted UI, no API Gateway)
**Events**: EventBridge + SQS for decoupled inter-service communication
**Infra**: Terraform, validated against MiniStack (local AWS emulator) to avoid real cloud cost during development
**Mobile**: Flutter — custom duotone (emerald/violet) design system, 3-tab navigation (Inventory, Orders, Alerts)

## The Three Services

- **`inventory-service`** — CRUD for inventory items, publishes `LowStockDetected` events to EventBridge when stock drops below threshold
- **`order-service`** — creates orders, synchronously reserves stock by calling `inventory-service`'s update endpoint
- **`notification-service`** — polls the SQS queue fed by EventBridge, processes low-stock alerts

## Why These Design Choices

- **ECS Fargate over Lambda**: these are long-running, connection-pooling services — a different workload shape than PulseOps' bursty alert logic, justifying a different compute model.
- **ALB-native Cognito over API Gateway + Lambda authorizer**: the architecture is ALB-fronted from the start; adding API Gateway on top would be a redundant second entry point.
- **Row-Level Security over application-layer filtering**: tenant isolation enforced by the database itself. See `docs/multi-tenancy.md` for the full design, including two real RLS bypass gotchas found and fixed during development.
- **EventBridge + SQS over direct HTTP calls (for alerts)**: `inventory-service` has no knowledge that `notification-service` exists — a failure in notification processing can't cascade into inventory operations.
- **Synchronous HTTP over event-driven (for order → stock reservation)**: order placement needs an immediate success/failure response to the user ("insufficient stock" must be known before confirming the order) — a deliberately different pattern than the alert pipeline, chosen because the two flows have different consistency requirements.

## Known Limitations (documented, not hidden)

- **No real human notification**: `notification-service` logs alerts and processes the event pipeline correctly, but doesn't yet send email/SMS. See `docs/event-driven-architecture.md` for the scoped-out design (tenant contacts table, SES integration).
- **Order → inventory reservation is not transactional**: a failure after stock decrements but before the order record is written has no rollback. A production version would need a saga pattern or outbox table.
- **Validated against MiniStack, not real AWS**: built under a zero-cost constraint (see `docs/` for reasoning) — Terraform is correct and applies cleanly, but hasn't been proven against a real AWS account.

## What I'd Add Next

- Real email/SMS delivery for alerts (SES or FCM, reusing the PulseOps pattern)
- Transactional/saga-based order-inventory coordination
- Automated integration tests (testcontainers-based, real Postgres in CI)
- Rate limiting per tenant at the ALB layer
- ALB fronting for order-service (currently direct port access only)

## Documentation

- [`docs/multi-tenancy.md`](docs/multi-tenancy.md) — RLS design, two real security gaps found and fixed
- [`docs/event-driven-architecture.md`](docs/event-driven-architecture.md) — EventBridge/SQS design, debugging notes, and the notification gap
- [`docs/cognito-auth.md`](docs/cognito-auth.md) — Auth architecture and tenant resolution
