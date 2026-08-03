# ShipFlow

> **A multi-tenant SaaS inventory and order management platform built with Flutter, Node.js microservices, PostgreSQL Row-Level Security, AWS, Docker, Terraform, and event-driven messaging.**

ShipFlow is a production-oriented inventory and order management platform designed for multiple businesses to operate on the same application while maintaining strict tenant-level data isolation.

The project focuses on engineering challenges beyond basic CRUD applications: **multi-tenancy, database-level isolation, service boundaries, synchronous vs. asynchronous communication, event-driven workflows, authentication, containerization, and infrastructure as code.**

---

## Architecture

![ShipFlow Architecture](docs/architecture.png)

### High-Level Flow

```text
Flutter Mobile App
        │
        │ HTTPS
        ▼
Application Load Balancer
        │
        │ Cognito Authentication
        ▼
┌─────────────────────────────────────────────────┐
│                 ECS / Fargate                   │
│                                                 │
│  ┌─────────────────┐      HTTP      ┌─────────┐ │
│  │ inventory-      │◄───────────────│ order-  │ │
│  │ service         │                │ service │ │
│  └────────┬────────┘                └────┬────┘ │
│           │                              │      │
└───────────┼──────────────────────────────┼──────┘
            │                              │
            ▼                              ▼
       PostgreSQL                    PostgreSQL
        + RLS                           + RLS
            │
            │ LowStockDetected
            ▼
      Amazon EventBridge
            │
            ▼
          Amazon SQS
            │
            ▼
   notification-service
```

ShipFlow deliberately uses **two different communication patterns**:

* **Synchronous HTTP** for order → inventory stock reservation, because the user needs an immediate success/failure response.
* **Asynchronous EventBridge + SQS** for low-stock notifications, so notification processing remains decoupled from inventory operations.

---

# Core Features

### Inventory

* Create, read, update, and delete inventory items
* SKU and stock-level tracking
* Tenant-scoped inventory
* Configurable low-stock threshold
* Automatic low-stock event generation

### Orders

* Create orders from available inventory
* Check stock availability before placing an order
* Synchronously reserve/decrement inventory
* Tenant-scoped order history

### Low-Stock Alerts

When inventory falls below a tenant's configured threshold:

```text
Inventory stock update
        ↓
Threshold evaluation
        ↓
LowStockDetected event
        ↓
EventBridge
        ↓
SQS
        ↓
notification-service
        ↓
Alert processing
```

### Multi-Tenancy

Tenant isolation is enforced at the PostgreSQL database layer using **Row-Level Security (RLS)**.

Instead of relying exclusively on application-level filtering, each request establishes a tenant context and PostgreSQL policies restrict access to rows belonging to that tenant.

This creates a second line of defense against accidental cross-tenant data access.

---

# Technology Stack

| Layer                | Technology                                 |
| -------------------- | ------------------------------------------ |
| Mobile               | Flutter                                    |
| Backend              | Node.js / Express                          |
| Architecture         | Microservices                              |
| Compute              | AWS ECS / Fargate                          |
| Load Balancing       | Application Load Balancer                  |
| Authentication       | Amazon Cognito + ALB-native authentication |
| Database             | PostgreSQL / Amazon RDS                    |
| Data Isolation       | PostgreSQL Row-Level Security              |
| Events               | Amazon EventBridge                         |
| Queuing              | Amazon SQS                                 |
| Containers           | Docker                                     |
| Infrastructure       | Terraform                                  |
| Local AWS Validation | MiniStack                                  |
| Messaging Pattern    | Event-driven + synchronous HTTP            |

---

# Microservices

ShipFlow is divided into three independently deployable services.

## `inventory-service`

Responsible for:

* Inventory CRUD
* Tenant-scoped database access
* Stock-level updates
* Per-tenant low-stock thresholds
* Publishing `LowStockDetected` events

Example event:

```json
{
  "tenantId": "tenant-a",
  "sku": "A-001",
  "name": "Tenant A Widget",
  "stockLevel": 5
}
```

---

## `order-service`

Responsible for:

* Order creation
* Order retrieval
* Stock availability validation
* Synchronous communication with `inventory-service`
* Stock reservation/decrement

The order workflow intentionally uses synchronous communication:

```text
Client
  ↓
order-service
  ↓ HTTP
inventory-service
  ↓
Check stock
  ↓
Reserve stock
  ↓
Create order
```

The immediate response matters here — the client needs to know whether the order could actually be placed.

---

## `notification-service`

Responsible for:

* Consuming low-stock messages from SQS
* Processing low-stock events
* Logging/handling alerts

It does **not** need to know that `inventory-service` exists.

Instead:

```text
inventory-service
      ↓
 EventBridge
      ↓
     SQS
      ↓
notification-service
```

This keeps notification processing decoupled from the inventory service.

---

# Multi-Tenant Data Isolation

One of the central design goals of ShipFlow is preventing Tenant A from accessing Tenant B's data.

The application establishes the tenant context for each request:

```text
Authenticated Request
        ↓
Tenant Identity
        ↓
Application Tenant Context
        ↓
PostgreSQL Session
        ↓
RLS Policy
        ↓
Only matching tenant rows
```

The database enforces the boundary using PostgreSQL Row-Level Security.

Conceptually:

```sql
CREATE POLICY tenant_isolation_policy
ON inventory_items
USING (
    tenant_id = current_setting(
        'app.current_tenant_id',
        true
    )
);
```

The same tenant-isolation approach is applied to the relevant transactional data.

### Why RLS?

Application-level filtering alone creates a dangerous failure mode:

```text
SELECT * FROM inventory_items;
```

A buggy repository or missing `WHERE tenant_id = ...` could potentially expose another tenant's data.

With RLS enabled, the database itself becomes an enforcement boundary.

See [`docs/multi-tenancy.md`](docs/multi-tenancy.md) for the detailed design and the two RLS-related security issues discovered and fixed during development.

---

# Authentication

ShipFlow currently uses:

```text
Flutter
   ↓
Application Load Balancer
   ↓
Amazon Cognito
   ↓
Authenticated request
   ↓
Backend services
```

The architecture uses **ALB-native Cognito authentication** rather than adding API Gateway and a custom Lambda authorizer.

This keeps the current architecture centered around the ALB as the primary entry point.

---

# Event-Driven Architecture

Low-stock alerts use an asynchronous architecture:

```text
inventory-service
       │
       │ LowStockDetected
       ▼
 EventBridge
       │
       ▼
      SQS
       │
       ▼
notification-service
```

### Why EventBridge + SQS?

The inventory service doesn't need to know how notifications are processed.

That means the notification path can fail or become temporarily unavailable without requiring inventory operations to synchronously wait for it.

This creates a clean separation between:

**Core transactional workflow**

and

**Secondary asynchronous processing**

See [`docs/event-driven-architecture.md`](docs/event-driven-architecture.md).

---

# Why These Architecture Decisions?

## ECS Fargate instead of Lambda

ShipFlow's services are long-running containerized applications that maintain database connection pools and represent continuously running service workloads.

This differs from the bursty, short-lived alert-processing workload used in PulseOps.

The choice demonstrates that compute architecture should follow workload characteristics rather than defaulting to one technology.

---

## PostgreSQL RLS instead of application-only filtering

Multi-tenancy is enforced at the database layer.

The application establishes tenant context, while PostgreSQL policies enforce which rows can be accessed.

This provides a stronger isolation boundary than relying entirely on developers remembering to add tenant filters to every query.

---

## EventBridge + SQS instead of direct notification calls

Inventory processing doesn't directly depend on the notification service.

Instead:

```text
inventory-service
       ↓
 EventBridge
       ↓
     SQS
       ↓
notification-service
```

This decouples the services and allows notification processing to happen asynchronously.

---

## Synchronous HTTP for stock reservation

Order creation is different.

When a customer places an order, ShipFlow needs an immediate answer:

> Is there enough inventory to place the order?

Therefore:

```text
order-service
      ↓ HTTP
inventory-service
      ↓
stock validation
      ↓
stock decrement
```

This is intentionally synchronous because the consistency requirement is different from the low-stock notification workflow.

---

# Infrastructure & DevOps

ShipFlow's infrastructure is managed with Terraform.

The services are containerized using Docker and designed for deployment on ECS/Fargate.

Terraform configuration is validated against **MiniStack**, allowing infrastructure development and testing without continuously incurring real AWS costs.

### Infrastructure tooling

* Terraform
* Docker
* ECS/Fargate
* Application Load Balancer
* RDS PostgreSQL
* EventBridge
* SQS
* Cognito

---

# Project Structure

```text
shipflow/
│
├── mobile/
│   └── lib/
│       └── features/
│           ├── inventory/
│           ├── orders/
│           ├── alerts/
│           └── tenant_admin/
│
├── services/
│   ├── inventory-service/
│   │   ├── index.js
│   │   ├── Dockerfile
│   │   └── schema.sql
│   │
│   ├── order-service/
│   │   ├── index.js
│   │   ├── Dockerfile
│   │   └── schema.sql
│   │
│   └── notification-service/
│       ├── src/
│       └── Dockerfile
│
├── infra/
│   └── terraform/
│
├── docs/
│   ├── multi-tenancy.md
│   ├── event-driven-architecture.md
│   └── cognito-auth.md
│
└── README.md
```

---

# Known Limitations

ShipFlow intentionally documents what is **not yet production-complete**.

## Notification delivery

`notification-service` currently processes and logs low-stock alerts but does not yet send real email/SMS notifications.

Potential production implementation:

```text
notification-service
       ↓
Amazon SES / FCM
       ↓
Tenant notification
```

See [`docs/event-driven-architecture.md`](docs/event-driven-architecture.md).

---

## Order / Inventory Transaction Boundary

Order creation and inventory reservation currently span two services.

The workflow is not a distributed transaction.

A failure after inventory is decremented but before the order is persisted could leave the system in an inconsistent state.

A production implementation could introduce:

* Saga pattern
* Transactional outbox
* Idempotent operations
* Compensation events

---

## Cloud Validation

Infrastructure has been validated against MiniStack rather than continuously deployed to real AWS infrastructure.

This was an intentional zero-cost development constraint.

Terraform configuration is therefore treated as infrastructure-as-code that is validated locally, rather than claiming that the complete production infrastructure has been battle-tested in a live AWS environment.

---

## Current Deployment Gap

The architecture is designed around an ALB entry point, but the current `order-service` implementation is not yet fully fronted through the ALB in the same way as the inventory path.

A production follow-up would route the order service through the same authenticated entry architecture.

---

# What I'd Build Next

1. **Real notification delivery**

   * Amazon SES / FCM
   * Tenant notification preferences

2. **Distributed transaction reliability**

   * Saga-based order workflow
   * Transactional outbox
   * Idempotency

3. **Automated integration testing**

   * Testcontainers
   * Real PostgreSQL integration tests
   * Event contract tests

4. **Tenant-aware rate limiting**

   * Per-tenant request limits

5. **Complete ALB routing**

   * Route `order-service` through the authenticated entry point

6. **Production observability**

   * Distributed tracing
   * Centralized structured logging
   * Service-level metrics and alarms

---

# Documentation

* [`docs/multi-tenancy.md`](docs/multi-tenancy.md) — PostgreSQL RLS design, tenant isolation strategy, and security gaps discovered and fixed.
* [`docs/event-driven-architecture.md`](docs/event-driven-architecture.md) — EventBridge + SQS architecture, low-stock event flow, notification processing, and known limitations.
* [`docs/cognito-auth.md`](docs/cognito-auth.md) — Cognito authentication architecture and tenant identity resolution.

---

# Engineering Takeaways

ShipFlow was built to explore several problems that don't appear in a basic CRUD application:

* How do you isolate multiple tenants sharing the same database?
* Where should tenant isolation actually be enforced?
* When should microservices communicate synchronously?
* When should communication become asynchronous?
* How do you prevent secondary workflows from blocking core transactions?
* What happens when a distributed workflow partially fails?
* How should infrastructure be represented as code?
* How do you make architecture decisions based on workload rather than technology trends?

The most important lesson:

> **Architecture is less about using as many technologies as possible and more about choosing the right boundary, consistency model, and failure behavior for each part of the system.**

---

# Project Status

**Active development**

ShipFlow is the flagship project in my portfolio and is being developed incrementally toward a more production-grade multi-tenant SaaS architecture.
