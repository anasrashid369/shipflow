resource "aws_ecr_repository" "notification_service" {
  name                 = "shipflow-notification-service"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "shipflow-notification-service"
  }
}

resource "aws_ecs_task_definition" "notification_service" {
  family                   = "shipflow-notification-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "notification-service"
      image     = "localhost:4566/shipflow-notification-service:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3001
          hostPort      = 3001
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "QUEUE_URL", value = aws_sqs_queue.low_stock_notifications.url },
        { name = "AWS_REGION", value = "us-east-1" },
        { name = "SQS_ENDPOINT", value = "http://ministack:4566" }
      ]
    }
  ])

  tags = {
    Name = "shipflow-notification-service-task"
  }
}

resource "aws_security_group" "notification_service" {
  name        = "shipflow-notification-service-sg"
  description = "Notification service - outbound only, no inbound needed"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shipflow-notification-service-sg"
  }
}

resource "aws_ecs_service" "notification_service" {
  name            = "shipflow-notification-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notification_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.notification_service.id]
    assign_public_ip = true
  }

  tags = {
    Name = "shipflow-notification-service"
  }
}