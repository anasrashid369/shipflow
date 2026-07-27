resource "aws_sqs_queue" "low_stock_notifications" {
  name                      = "shipflow-low-stock-notifications"
  message_retention_seconds = 86400

  tags = {
    Name = "shipflow-low-stock-notifications"
  }
}

resource "aws_cloudwatch_event_rule" "low_stock" {
  name        = "shipflow-low-stock-rule"
  description = "Route low stock events to the notification queue"

  event_pattern = jsonencode({
    source      = ["shipflow.inventory-service"]
    detail-type = ["LowStockDetected"]
  })

  tags = {
    Name = "shipflow-low-stock-rule"
  }
}

resource "aws_cloudwatch_event_target" "low_stock_to_sqs" {
  rule      = aws_cloudwatch_event_rule.low_stock.name
  target_id = "low-stock-sqs-target"
  arn       = aws_sqs_queue.low_stock_notifications.arn
}

resource "aws_sqs_queue_policy" "allow_eventbridge" {
  queue_url = aws_sqs_queue.low_stock_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.low_stock_notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.low_stock.arn
          }
        }
      }
    ]
  })
}