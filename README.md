# ShipFlow

A multi-tenant SaaS inventory and order management platform — built on an event-driven, containerized AWS architecture (ECS/Fargate, RDS with row-level security, EventBridge).

**Status:** In active development.

## Planned Architecture

- **Backend**: Node.js microservices (inventory-service, order-service, notification-service) on ECS Fargate
- **Database**: PostgreSQL (RDS) with row-level security for tenant isolation
- **Events**: EventBridge for inter-service communication
- **Infra**: Terraform
- **Mobile**: Flutter

More details coming as each phase is built.