require("dotenv").config();
const express = require("express");
const { Pool } = require("pg");
const { EventBridgeClient, PutEventsCommand } = require("@aws-sdk/client-eventbridge");
const cors = require("cors");
const app = express();
app.use(express.json());
app.use(cors());

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "shipflow",
});

const eventBridgeClient = new EventBridgeClient({
  region: process.env.AWS_REGION || "us-east-1",
  endpoint: process.env.EVENTBRIDGE_ENDPOINT || "http://localhost:4566",
  credentials: { accessKeyId: "test", secretAccessKey: "test" },
});

const LOW_STOCK_THRESHOLD = 10;

async function publishLowStockEvent(tenantId, item) {
  try {
    await eventBridgeClient.send(
      new PutEventsCommand({
        Entries: [
          {
            Source: "shipflow.inventory-service",
            DetailType: "LowStockDetected",
            Detail: JSON.stringify({
              tenantId,
              sku: item.sku,
              name: item.name,
              stockLevel: item.stock_level,
            }),
            EventBusName: "default",
          },
        ],
      })
    );
    console.log(`Published low-stock event for SKU ${item.sku}`);
  } catch (err) {
    console.error("Failed to publish low-stock event:", err);
  }
}

// Middleware: require a tenant ID on every request (except health check)
function extractTenantFromAlbHeader(req) {
  const oidcData = req.header("x-amzn-oidc-data");
  if (!oidcData) return null;
  try {
    // ALB's JWT: header.payload.signature (base64url encoded)
    const payloadBase64 = oidcData.split(".")[1];
    const payload = JSON.parse(Buffer.from(payloadBase64, "base64").toString("utf8"));
    return payload["custom:tenant_id"] || null;
  } catch (err) {
    console.error("Failed to decode ALB OIDC data:", err.message);
    return null;
  }
}

app.use((req, res, next) => {
  if (req.path === "/health") return next();

  // Prefer the ALB-authenticated, Cognito-verified tenant claim.
  // Fall back to the client-supplied header only for local/direct testing
  // (bypassing the ALB), never trusted in a real deployment.
  const tenantFromAlb = extractTenantFromAlbHeader(req);
  const tenantId = tenantFromAlb || req.header("X-Tenant-Id");

  if (!tenantId) {
    return res.status(400).json({ success: false, error: "Missing tenant identity (no ALB auth header or X-Tenant-Id)" });
  }
  req.tenantId = tenantId;
  next();
});

// Helper: run a query scoped to the current request's tenant
async function queryAsTenant(tenantId, queryText, params) {
  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.current_tenant_id', $1, false)", [tenantId]);
    const result = await client.query(queryText, params);
    return result;
  } finally {
    client.release();
  }
}

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.get("/inventory", async (req, res) => {
  try {
    const result = await queryAsTenant(
      req.tenantId,
      "SELECT * FROM inventory_items ORDER BY created_at DESC"
    );
    res.json({ success: true, items: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post("/inventory", async (req, res) => {
  try {
    const { sku, name, stock_level } = req.body;
    const result = await queryAsTenant(
      req.tenantId,
      "INSERT INTO inventory_items (tenant_id, sku, name, stock_level) VALUES ($1, $2, $3, $4) RETURNING *",
      [req.tenantId, sku, name, stock_level || 0]
    );
    res.status(201).json({ success: true, item: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

app.patch("/inventory/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { stock_level } = req.body;
    const result = await queryAsTenant(
      req.tenantId,
      "UPDATE inventory_items SET stock_level = $1, updated_at = NOW() WHERE id = $2 RETURNING *",
      [stock_level, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: "Item not found" });
    }

    const item = result.rows[0];

    if (item.stock_level < LOW_STOCK_THRESHOLD) {
      await publishLowStockEvent(req.tenantId, item);
    }

    res.json({ success: true, item });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete("/inventory/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await queryAsTenant(
      req.tenantId,
      "DELETE FROM inventory_items WHERE id = $1 RETURNING *",
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: "Item not found" });
    }
    res.json({ success: true, message: "Item deleted" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`inventory-service listening on port ${PORT}`);
});