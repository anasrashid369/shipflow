require("dotenv").config();
const express = require("express");
const { Pool } = require("pg");
const fetch = require("node-fetch");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || "app_user",
  password: process.env.DB_PASSWORD || "app_password",
  database: process.env.DB_NAME || "shipflow",
});

const INVENTORY_URL = process.env.INVENTORY_SERVICE_URL || "http://localhost:3000";

app.use((req, res, next) => {
  if (req.path === "/health") return next();
  const tenantId = req.header("X-Tenant-Id");
  if (!tenantId) return res.status(400).json({ success: false, error: "Missing X-Tenant-Id header" });
  req.tenantId = tenantId;
  next();
});

async function queryAsTenant(tenantId, queryText, params) {
  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.current_tenant_id', $1, false)", [tenantId]);
    return await client.query(queryText, params);
  } finally {
    client.release();
  }
}

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.get("/orders", async (req, res) => {
  try {
    const result = await queryAsTenant(req.tenantId, "SELECT * FROM orders ORDER BY created_at DESC");
    res.json({ success: true, orders: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post("/orders", async (req, res) => {
  try {
    const { itemId, sku, quantity } = req.body;

    // Reserve stock via inventory-service (synchronous, reuses existing endpoint)
    const invResp = await fetch(`${INVENTORY_URL}/inventory`, {
      headers: { "X-Tenant-Id": req.tenantId },
    });
    const invData = await invResp.json();
    const item = invData.items.find((i) => i.id === itemId);

    if (!item) return res.status(404).json({ success: false, error: "Item not found" });
    if (item.stock_level < quantity) {
      return res.status(400).json({ success: false, error: "Insufficient stock" });
    }

    await fetch(`${INVENTORY_URL}/inventory/${itemId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-Tenant-Id": req.tenantId },
      body: JSON.stringify({ stock_level: item.stock_level - quantity }),
    });

    const result = await queryAsTenant(
      req.tenantId,
      "INSERT INTO orders (tenant_id, sku, quantity, status) VALUES ($1, $2, $3, 'placed') RETURNING *",
      [req.tenantId, sku, quantity]
    );

    res.status(201).json({ success: true, order: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3002;
app.listen(PORT, () => console.log(`order-service listening on port ${PORT}`));