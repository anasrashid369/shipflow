# Event-Driven Architecture: inventory-service → notification-service

## The pattern

`inventory-service` and `notification-service` communicate asynchronously via **Amazon EventBridge → SQS**, not direct HTTP calls. This is a deliberate architectural choice:

- `inventory-service` has **zero knowledge** that `notification-service` exists. It publishes a `LowStockDetected` event to EventBridge and moves on.
- If `notification-service` is down, slow, or being redeployed, `inventory-service`'s requests are completely unaffected — the event sits safely in SQS until a consumer is available.
- Adding a third service that also needs to react to low-stock events requires **zero changes** to `inventory-service` — just a new EventBridge target.

## Flow

inventory-service (PATCH /inventory/:id, stock_level < 10)
→ EventBridge.putEvents({ source: "shipflow.inventory-service", detail-type: "LowStockDetected", ... })
→ EventBridge rule matches (source + detail-type filter)
→ routes to SQS queue "shipflow-low-stock-notifications"
→ notification-service polls the queue every 5s
→ logs the alert, deletes the message


## Why SQS as the target (not a direct HTTP API destination)

EventBridge can deliver directly to an HTTP endpoint via API Destinations, but SQS was chosen instead because:

- **Durability**: if `notification-service` is temporarily down, the event waits in the queue rather than being dropped or requiring EventBridge's own retry/DLQ handling for HTTP failures.
- **Backpressure handling**: a burst of low-stock events (e.g., a bulk order draining multiple SKUs at once) queues naturally instead of overwhelming `notification-service` with concurrent HTTP requests.
- **Realistic pattern**: EventBridge → SQS → consumer is a standard, widely-used AWS pattern for exactly this kind of "fan-out with reliable processing" use case.

## Local testing scope (a deliberate boundary)

- **`docker-compose up`** (in `services/inventory-service/`) tests `inventory-service`'s CRUD and RLS logic against local Postgres — fast iteration, no cloud dependencies.
- **EventBridge/SQS integration** is tested against the full Terraform-provisioned stack (via MiniStack), since it's genuinely cross-service cloud infrastructure, not local business logic. This mirrors how real teams typically separate fast local dev loops from fuller staging-environment integration tests.

## Debugging notes worth documenting

Two non-obvious issues surfaced while building this, both around container networking:

1. **`localhost` inside a container refers to the container itself**, not the host machine. Both `inventory-service` (publishing to EventBridge) and `notification-service` (polling SQS) initially pointed at `localhost:4566`, which silently failed inside their containers. Fixed by using `host.docker.internal:4566` — the standard Docker Desktop mechanism for a container to reach services running on the host.
2. **MiniStack's ECS simulation does not automatically restart a stopped task** the way real AWS ECS does (which continuously reconciles `runningCount` against `desiredCount`). A `force-new-deployment` call updates metadata but doesn't recreate the container. Workaround: toggle `desired-count` to 0 then back to 1, which reliably triggers a fresh container pull and start.