provider "aws" {
  region = "us-east-1"
}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "app_task" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-app-task"
  }
}

# -------------------------------
# Subnets Públicas
# -------------------------------
resource "aws_subnet" "pub_1a" {
  vpc_id                  = aws_vpc.app_task.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "subnet-pub-app-task-1a" }
}

resource "aws_subnet" "pub_1b" {
  vpc_id                  = aws_vpc.app_task.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "subnet-pub-app-task-1b" }
}

# -------------------------------
# Subnets Privadas
# -------------------------------
resource "aws_subnet" "priv_1c" {
  vpc_id                  = aws_vpc.app_task.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags                    = { Name = "subnet-priv-app-task-1c" }
}

resource "aws_subnet" "priv_1d" {
  vpc_id                  = aws_vpc.app_task.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags                    = { Name = "subnet-priv-app-task-1d" }
}

# -------------------------------
# Internet Gateway
# -------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_task.id
  tags   = { Name = "igw-app-task" }
}

# -------------------------------
# NAT Gateways (1 por AZ)
# -------------------------------
# Elastic IPs
resource "aws_eip" "nat_1a" {
  domain = "vpc"
}

resource "aws_eip" "nat_1b" {
  domain = "vpc"
}




# NATs
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.pub_1a.id
  tags          = { Name = "app-task-nat-gat-1a" }
}

resource "aws_nat_gateway" "nat_1b" {
  allocation_id = aws_eip.nat_1b.id
  subnet_id     = aws_subnet.pub_1b.id
  tags          = { Name = "app-task-nat-gat-1b" }
}

# -------------------------------
# Route Tables
# -------------------------------
# Rota pública
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.app_task.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-pub-app-task" }
}

# Associar subnets públicas
resource "aws_route_table_association" "pub_1a" {
  subnet_id      = aws_subnet.pub_1a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_1b" {
  subnet_id      = aws_subnet.pub_1b.id
  route_table_id = aws_route_table.pub.id
}

# Rota privada 1a
resource "aws_route_table" "priv_1c" {
  vpc_id = aws_vpc.app_task.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }
  tags = { Name = "rt-priv-app-task-1c" }
}

resource "aws_route_table_association" "priv_1c_assoc" {
  subnet_id      = aws_subnet.priv_1c.id
  route_table_id = aws_route_table.priv_1c.id
}

# Rota privada 1b
resource "aws_route_table" "priv_1d" {
  vpc_id = aws_vpc.app_task.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1b.id
  }
  tags = { Name = "rt-priv-app-task-1d" }
}

resource "aws_route_table_association" "priv_1d_assoc" {
  subnet_id      = aws_subnet.priv_1d.id
  route_table_id = aws_route_table.priv_1d.id
}

# -------------------------------
# ECS Cluster
# -------------------------------
resource "aws_ecs_cluster" "app_task" {
  name = "app-task-cluster"
}

# -------------------------------
# Security Groups
# -------------------------------
# ALB
resource "aws_security_group" "alb" {
  name        = "app-task-alb"
  description = "SG para o ALB"
  vpc_id      = aws_vpc.app_task.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task (frontend+backend)
resource "aws_security_group" "ecs" {
  name        = "app-task-ecs"
  description = "SG para ECS Tasks"
  vpc_id      = aws_vpc.app_task.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Só aceita tráfego do ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # permite saída para internet e RDS
  }
}

# RDS
resource "aws_security_group" "rds" {
  name        = "app-task-rds"
  description = "SG para RDS Postgres"
  vpc_id      = aws_vpc.app_task.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id] # só backend pode acessar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------
# Application Load Balancer
# -------------------------------
resource "aws_lb" "app_task_alb" {
  name               = "app-task-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.pub_1a.id,
    aws_subnet.pub_1b.id
  ]

  tags = { Name = "app-task-alb" }
}

# -------------------------------
# Target Group para backend
# -------------------------------
resource "aws_lb_target_group" "app_task_tg" {
  name        = "app-task-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_task.id
  target_type = "ip"

  health_check {
    path                = "/tasks"
    protocol            = "HTTP"
    interval            = 120
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "app-task-tg" }
}

# -------------------------------
# Listener HTTP
# -------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_task_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_task_tg.arn
  }
}

# -------------------------------
# RDS PostgreSQL
# -------------------------------
resource "aws_db_subnet_group" "app_task" {
  name       = "db-subnet-group-app-task"
  subnet_ids = [aws_subnet.priv_1c.id, aws_subnet.priv_1d.id]

  tags = {
    Name = "db-subnet-group-app-task"
  }
}

resource "aws_db_instance" "app_task" {
  identifier             = "app-task-db"
  engine                 = "postgres"
  engine_version         = "17.6"
  instance_class         = "db.t3.micro" # pode ajustar se quiser mais potência
  allocated_storage      = 20
  db_name                = "tasksdb"
  username               = "postgres"
  password               = "postgres"
  port                   = 5432
  publicly_accessible    = false
  storage_type           = "gp2"
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.app_task.name
  skip_final_snapshot    = true # cuidado, não cria snapshot ao destruir

  tags = {
    Name = "rds-app-task"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.app_task.endpoint
}

output "rds_port" {
  value = aws_db_instance.app_task.port
}

# -------------------------------
# IAM Role para ECS Task Execution
# -------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "app-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------
# ECS Task Definition
# -------------------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "886436950673.dkr.ecr.us-east-1.amazonaws.com/app-task-backend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        { name = "DB_HOST", value = "app-task-db.cmhcko6u60nk.us-east-1.rds.amazonaws.com" },
        { name = "DB_USER", value = "postgres" },
        { name = "DB_PASSWORD", value = "postgres" },
        { name = "DB_NAME", value = "tasksdb" },
        { name = "DB_PORT", value = "5432" }
      ]
    },
    {
      name      = "frontend"
      image     = "886436950673.dkr.ecr.us-east-1.amazonaws.com/app-task-frontend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# -------------------------------
# ECS Service
# -------------------------------
resource "aws_ecs_service" "app_task" {
  name            = "app-task-service"
  cluster         = aws_ecs_cluster.app_task.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.priv_1c.id, aws_subnet.priv_1d.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_task_tg.arn
    container_name   = "backend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}

