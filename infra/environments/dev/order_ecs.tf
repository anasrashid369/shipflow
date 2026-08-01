resource "aws_ecr_repository" "order_service" {
  name                 = "shipflow-order-service"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "shipflow-order-service"
  }
}

resource "aws_ecs_task_definition" "order_service" {
  family                   = "shipflow-order-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "order-service"
      image     = "localhost:4566/shipflow-order-service:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3002
          hostPort      = 3002
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_USER", value = "app_user" },
        { name = "DB_PASSWORD", value = "app_password" },
        { name = "DB_NAME", value = "shipflow" },
        { name = "INVENTORY_SERVICE_URL", value = "http://host.docker.internal:3000" }
      ]
    }
  ])

  tags = {
    Name = "shipflow-order-service-task"
  }
}

resource "aws_security_group" "order_service" {
  name        = "shipflow-order-service-sg"
  description = "Order service - accessible for local testing"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shipflow-order-service-sg"
  }
}

resource "aws_ecs_service" "order_service" {
  name            = "shipflow-order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.order_service.id]
    assign_public_ip = true
  }

  tags = {
    Name = "shipflow-order-service"
  }
}