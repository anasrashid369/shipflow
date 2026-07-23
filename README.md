# ShipFlow

A multi-tenant SaaS inventory and order management platform — built on an event-driven, containerized AWS architecture (ECS/Fargate, RDS with row-level security, EventBridge).

**Status:** In active development.

## Planned Architecture

- **Backend**: Node.js microservices (inventory-service, order-service, notification-service) on ECS Fargate
- **Database**: PostgreSQL (RDS) with row-level security for tenant isolation
- **Events**: EventBridge for inter-service communication
- **Infra**: Terraform
- **Mobile**: Flutter

## Phase 2: Infrastructure as Code (Terraform)

The `inventory-service` is deployed via Terraform to a full cloud-style architecture: VPC with public subnets across 2 availability zones, RDS PostgreSQL, ECS Fargate service, and an Application Load Balancer routing traffic to the containerized service.

### Why Terraform (not CDK, as used in a previous project)

Demonstrates range across the two major infrastructure-as-code tools. CDK excels for teams already in a TypeScript/JS ecosystem; Terraform's HCL and provider-agnostic design make it the more common choice for polyglot infra teams and multi-cloud setups.

### Local testing via MiniStack (not real AWS)

This infrastructure is validated against **MiniStack**, a free, open-source AWS API emulator, rather than a real AWS account. This was a deliberate choice: ECS Fargate, RDS, and Application Load Balancers all incur real, continuous cost on AWS (no meaningful free tier), and this project was built under a strict $0 budget constraint. MiniStack runs actual Docker containers for ECS tasks and a real Postgres instance for RDS, providing genuine functional validation — not just a syntax check — while guaranteeing zero cost.

**What this proves**: the Terraform code is correct and the architecture works end-to-end (verified via real HTTP requests against the deployed service, connected to a real database, all provisioned by `terraform apply`).

**What this doesn't prove**: real AWS-specific behaviors (actual network latency, real IAM edge cases, true multi-AZ failover) that only surface on genuine AWS infrastructure. A production deployment would run this same Terraform against a real AWS account.

### Known limitation: schema initialization

Unlike the local Docker Compose setup (Phase 1), which auto-runs `schema.sql` via Postgres's `docker-entrypoint-initdb.d` mechanism, RDS has no equivalent auto-init hook. In this deployment, the schema was applied manually via `psql` after provisioning. A production setup would use a dedicated migration tool (e.g., `node-pg-migrate`, `Flyway`) run as part of the deployment pipeline.

### Architecture (Phase 2)

Internet
↓
Application Load Balancer (public subnets, 2 AZs)
↓
ECS Fargate Service (inventory-service container)
↓
RDS PostgreSQL (private, only reachable from within VPC)


### Infrastructure components (Terraform)

- VPC with 2 public subnets (us-east-1a, us-east-1b), Internet Gateway, route tables
- RDS PostgreSQL 16 (db.t3.micro equivalent), isolated in a dedicated security group
- ECR repository for the container image
- ECS Cluster + Fargate Task Definition + Service (1 task, auto-restart on failure)
- Application Load Balancer + Target Group with `/health` health checks
- IAM execution role scoped to ECS task requirements only