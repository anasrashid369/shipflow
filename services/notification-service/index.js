require("dotenv").config();
const express = require("express");
const { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } = require("@aws-sdk/client-sqs");

const app = express();
app.use(express.json());

const sqsClient = new SQSClient({
  region: process.env.AWS_REGION || "us-east-1",
  endpoint: process.env.SQS_ENDPOINT || "http://localhost:4566",
  credentials: { accessKeyId: "test", secretAccessKey: "test" },
});

const QUEUE_URL = process.env.QUEUE_URL;

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

async function pollQueue() {
  if (!QUEUE_URL) {
    console.log("No QUEUE_URL configured, skipping poll");
    return;
  }

  try {
    const result = await sqsClient.send(
      new ReceiveMessageCommand({
        QueueUrl: QUEUE_URL,
        MaxNumberOfMessages: 5,
        WaitTimeSeconds: 10,
      })
    );

    if (result.Messages && result.Messages.length > 0) {
      for (const message of result.Messages) {
        const body = JSON.parse(message.Body);
        // EventBridge wraps the actual event in a "detail" field
        const detail = body.detail || body;

        console.log(
          `[LOW STOCK ALERT] Tenant: ${detail.tenantId} | SKU: ${detail.sku} (${detail.name}) | Stock level: ${detail.stockLevel}`
        );

        await sqsClient.send(
          new DeleteMessageCommand({
            QueueUrl: QUEUE_URL,
            ReceiptHandle: message.ReceiptHandle,
          })
        );
      }
    }
  } catch (err) {
    console.error("Error polling queue:", err.message);
  }
}

// Poll every 5 seconds
setInterval(pollQueue, 5000);

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`notification-service listening on port ${PORT}`);
  console.log("Starting SQS polling loop...");
});