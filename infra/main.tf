terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------------
# Variables
# -------------------------------
variable "environments" {
  description = "List of environments"
  type        = list(string)
  default     = ["staging", "prod"]
}

variable "domain_names" {
  description = "Domain names for each environment"
  type        = map(string)
  default = {
    staging = "staging.buildcloud.com.br"
    prod    = "www.buildcloud.com.br"
  }
}

# -------------------------------
# Data Sources
# -------------------------------
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  name         = "buildcloud.com.br"
  private_zone = false
}

# -------------------------------
# VPC (Shared)
# -------------------------------
resource "aws_vpc" "app_cicd" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "app-cicd-vpc"
    Project     = "app-cicd"
    ManagedBy   = "Terraform"
  }
}

# -------------------------------
# Subnets Públicas
# -------------------------------
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.app_cicd.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "app-cicd-public-subnet-a"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.app_cicd.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "app-cicd-public-subnet-b"
  }
}

# -------------------------------
# Subnets Privadas
# -------------------------------
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.app_cicd.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "app-cicd-private-subnet-a"
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.app_cicd.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "app-cicd-private-subnet-b"
  }
}

# -------------------------------
# Internet Gateway
# -------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_cicd.id
  tags = {
    Name = "app-cicd-igw"
  }
}

# -------------------------------
# NAT Gateways
# -------------------------------
resource "aws_eip" "nat_1a" {
  domain = "vpc"
  tags = {
    Name = "app-cicd-eip-nat-a"
  }
}

resource "aws_eip" "nat_1b" {
  domain = "vpc"
  tags = {
    Name = "app-cicd-eip-nat-b"
  }
}

resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public_1a.id
  tags = {
    Name = "app-cicd-natgw-a"
  }
}

resource "aws_nat_gateway" "nat_1b" {
  allocation_id = aws_eip.nat_1b.id
  subnet_id     = aws_subnet.public_1b.id
  tags = {
    Name = "app-cicd-natgw-b"
  }
}

# -------------------------------
# Route Tables
# -------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_cicd.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "app-cicd-rt-public"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.app_cicd.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }
  tags = {
    Name = "app-cicd-rt-private-a"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table" "private_1b" {
  vpc_id = aws_vpc.app_cicd.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1b.id
  }
  tags = {
    Name = "app-cicd-rt-private-b"
  }
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_1b.id
}

# -------------------------------
# ACM Certificates (Usar existentes)
# -------------------------------
locals {
  # ARN do certificado wildcard existente
  cert_arn = "arn:aws:acm:us-east-1:886436950673:certificate/62229f39-5889-4c06-81a9-70acd98cd380"
}

# -------------------------------
# S3 Buckets for Frontend
# -------------------------------
resource "aws_s3_bucket" "frontend" {
  for_each = toset(var.environments)
  bucket   = "app-cicd-frontend-${each.key}"

  tags = {
    Name        = "app-cicd-frontend-${each.key}"
    Environment = each.key
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  for_each = aws_s3_bucket.frontend
  bucket   = each.value.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  for_each = aws_s3_bucket.frontend
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------
# CloudFront Origin Access Control
# -------------------------------
resource "aws_cloudfront_origin_access_control" "frontend" {
  for_each                          = toset(var.environments)
  name                              = "app-cicd-oac-${each.key}"
  description                       = "OAC for app-cicd frontend ${each.key}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -------------------------------
# CloudFront Distributions
# -------------------------------
resource "aws_cloudfront_distribution" "frontend" {
  for_each = toset(var.environments)

  origin {
    domain_name              = aws_s3_bucket.frontend[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[each.key].id
    origin_id                = "S3-${aws_s3_bucket.frontend[each.key].id}"
  }

  origin {
    domain_name = aws_lb.backend[each.key].dns_name
    origin_id   = "ALB-${each.key}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_names[each.key]]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend[each.key].id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${each.key}"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = local.cert_arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name        = "app-cicd-cloudfront-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# S3 Bucket Policy for CloudFront
# -------------------------------
resource "aws_s3_bucket_policy" "frontend" {
  for_each = aws_s3_bucket.frontend
  bucket   = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${each.value.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend[each.key].arn
          }
        }
      }
    ]
  })
}

# -------------------------------
# Route53 Records for CloudFront
# -------------------------------
resource "aws_route53_record" "frontend" {
  for_each = toset(var.environments)
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = var.domain_names[each.key]
  type     = "A"
  
  # Permitir sobrescrever registros existentes
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.frontend[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.frontend[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}

# -------------------------------
# ECS Cluster
# -------------------------------
resource "aws_ecs_cluster" "app_cicd" {
  name = "app-cicd-cluster"

  tags = {
    Name = "app-cicd-cluster"
  }
}

# -------------------------------
# Security Groups
# -------------------------------
resource "aws_security_group" "alb" {
  for_each    = toset(var.environments)
  name        = "app-cicd-alb-sg-${each.key}"
  description = "Security group for ALB ${each.key}"
  vpc_id      = aws_vpc.app_cicd.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

  tags = {
    Name        = "app-cicd-alb-sg-${each.key}"
    Environment = each.key
  }
}

resource "aws_security_group" "ecs_backend" {
  for_each    = toset(var.environments)
  name        = "app-cicd-ecs-backend-sg-${each.key}"
  description = "Security group for ECS Backend ${each.key}"
  vpc_id      = aws_vpc.app_cicd.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[each.key].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-cicd-ecs-backend-sg-${each.key}"
    Environment = each.key
  }
}

resource "aws_security_group" "rds" {
  for_each    = toset(var.environments)
  name        = "app-cicd-rds-sg-${each.key}"
  description = "Security group for RDS ${each.key}"
  vpc_id      = aws_vpc.app_cicd.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_backend[each.key].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-cicd-rds-sg-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# Application Load Balancers
# -------------------------------
resource "aws_lb" "backend" {
  for_each           = toset(var.environments)
  name               = "app-cicd-alb-${each.key}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[each.key].id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]

  tags = {
    Name        = "app-cicd-alb-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# Target Groups
# -------------------------------
resource "aws_lb_target_group" "backend" {
  for_each    = toset(var.environments)
  name        = "app-cicd-backend-tg-${each.key}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_cicd.id
  target_type = "ip"

  health_check {
    path                = "/tasks"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "app-cicd-backend-tg-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# ALB Listeners
# -------------------------------
resource "aws_lb_listener" "backend" {
  for_each          = toset(var.environments)
  load_balancer_arn = aws_lb.backend[each.key].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend[each.key].arn
  }
}

# -------------------------------
# RDS Subnet Groups
# -------------------------------
resource "aws_db_subnet_group" "app_cicd" {
  for_each   = toset(var.environments)
  name       = "app-cicd-db-subnet-group-${each.key}"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]

  tags = {
    Name        = "app-cicd-db-subnet-group-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# RDS Instances
# -------------------------------
resource "aws_db_instance" "app_cicd" {
  for_each               = toset(var.environments)
  identifier             = "app-cicd-db-${each.key}"
  engine                 = "postgres"
  engine_version         = "17.6"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "tasksdb"
  username               = "postgres"
  password               = "postgres123"
  port                   = 5432
  publicly_accessible    = false
  storage_type           = "gp2"
  vpc_security_group_ids = [aws_security_group.rds[each.key].id]
  db_subnet_group_name   = aws_db_subnet_group.app_cicd[each.key].name
  skip_final_snapshot    = true

  tags = {
    Name        = "app-cicd-db-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# IAM Role for ECS Task Execution
# -------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "app-cicd-execution-role"

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
# CloudWatch Log Groups
# -------------------------------
resource "aws_cloudwatch_log_group" "backend" {
  for_each          = toset(var.environments)
  name              = "/ecs/app-cicd/backend/${each.key}"
  retention_in_days = 7

  tags = {
    Name        = "app-cicd-logs-backend-${each.key}"
    Environment = each.key
  }
}

# -------------------------------
# ECR Repository
# -------------------------------
resource "aws_ecr_repository" "backend" {
  name = "app-cicd-backend"

  tags = {
    Name = "app-cicd-backend-repo"
  }
}

# -------------------------------
# ECS Task Definitions
# -------------------------------
resource "aws_ecs_task_definition" "backend" {
  for_each                 = toset(var.environments)
  family                   = "app-cicd-backend-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/app-cicd-backend:${each.key}"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.app_cicd[each.key].address },
        { name = "DB_USER", value = "postgres" },
        { name = "DB_PASSWORD", value = "postgres123" },
        { name = "DB_NAME", value = "tasksdb" },
        { name = "DB_PORT", value = "5432" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/app-cicd/backend/${each.key}"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# -------------------------------
# ECS Services
# -------------------------------
resource "aws_ecs_service" "backend" {
  for_each        = toset(var.environments)
  name            = "app-cicd-backend-svc-${each.key}"
  cluster         = aws_ecs_cluster.app_cicd.id
  task_definition = aws_ecs_task_definition.backend[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
    security_groups  = [aws_security_group.ecs_backend[each.key].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend[each.key].arn
    container_name   = "backend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.backend]
}

# -------------------------------
# Outputs
# -------------------------------
output "cloudfront_domains" {
  value = {
    for env in var.environments : env => {
      domain     = var.domain_names[env]
      cloudfront = aws_cloudfront_distribution.frontend[env].domain_name
    }
  }
}

output "backend_alb_dns" {
  value = {
    for env in var.environments : env => aws_lb.backend[env].dns_name
  }
}

output "rds_endpoints" {
  value = {
    for env in var.environments : env => aws_db_instance.app_cicd[env].endpoint
  }
}

output "s3_buckets" {
  value = {
    for env in var.environments : env => aws_s3_bucket.frontend[env].bucket
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}