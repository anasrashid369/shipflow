require("dotenv").config();
const express = require("express");
const { Pool } = require("pg");

const app = express();
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "shipflow",
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// List all inventory items
app.get("/inventory", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM inventory_items ORDER BY created_at DESC");
    res.json({ success: true, items: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Create a new inventory item
app.post("/inventory", async (req, res) => {
  try {
    const { sku, name, stock_level } = req.body;
    const result = await pool.query(
      "INSERT INTO inventory_items (sku, name, stock_level) VALUES ($1, $2, $3) RETURNING *",
      [sku, name, stock_level || 0]
    );
    res.status(201).json({ success: true, item: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Update stock level
app.patch("/inventory/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { stock_level } = req.body;
    const result = await pool.query(
      "UPDATE inventory_items SET stock_level = $1, updated_at = NOW() WHERE id = $2 RETURNING *",
      [stock_level, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: "Item not found" });
    }
    res.json({ success: true, item: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Delete an item
app.delete("/inventory/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM inventory_items WHERE id = $1 RETURNING *", [id]);
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