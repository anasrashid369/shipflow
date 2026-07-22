resource "aws_ecs_cluster" "main" {
  name = "shipflow-cluster"

  tags = {
    Name = "shipflow-cluster"
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "shipflow-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "inventory_service" {
  family                   = "shipflow-inventory-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "inventory-service"
      image     = "${aws_ecr_repository.inventory_service.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_USER", value = "postgres" },
        { name = "DB_PASSWORD", value = "localdevpassword" },
        { name = "DB_NAME", value = "shipflow" }
      ]
    }
  ])

  tags = {
    Name = "shipflow-inventory-service-task"
  }
}