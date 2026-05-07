# Terraform Infrastructure as Code

> Reference for: DevOps Engineer
> Load when: Infrastructure as code, AWS/GCP provisioning, Terraform modules
> **Version requirement**: Use latest stable Terraform and AWS provider versions at invocation time

## Version Fetching

Before writing Terraform configuration, determine latest stable versions:

```bash
# Get latest stable Terraform version
TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases | \
  jq -r '.[] | select(.prerelease==false) | .tag_name' | head -1 | sed 's/v//')

# Get latest stable AWS provider version
AWS_PROVIDER_VERSION=$(curl -s "https://registry.terraform.io/v1/providers/hashicorp/aws/versions" | \
  jq -r '.versions[] | select(.official==true and .archived==false) | .version' | head -1)

echo "Terraform: $TERRAFORM_VERSION"
echo "AWS Provider: $AWS_PROVIDER_VERSION"
```

## AWS ECS Fargate Setup

```hcl
terraform {
  required_version = ">= 1.15.0"
  required_providers {
    aws = { 
      source  = "hashicorp/aws"
      version = ">= 5.0"  # Use latest available 5.x or higher
    }
  }
  backend "s3" {
    bucket = "terraform-state"
    key    = "app/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "app-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = "${var.ecr_repository}:${var.image_tag}"
    portMappings = [{ containerPort = 3000 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "app"
      }
    }
    secrets = [
      { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.db_url.arn }
    ]
  }])
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.app.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 3000
  }
}
```

## AWS RDS PostgreSQL

```hcl
# Always use latest stable PostgreSQL engine version
# Get latest: aws rds describe-db-engine-versions --engine postgres --query 'DBEngineVersions[0].EngineVersion'

resource "aws_db_instance" "postgres" {
  identifier           = "app-db"
  engine               = "postgres"
  engine_version       = "17"  # Use latest available stable version
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_encrypted    = true

  db_name              = "app"
  username             = "admin"
  password             = var.db_password

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  skip_final_snapshot     = false
  final_snapshot_identifier = "app-db-final"

  tags = { Environment = var.environment }
}
```

## Variables and Outputs

```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# outputs.tf
output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
```

## Best Practices

| Practice | Implementation |
|----------|----------------|
| State locking | S3 backend with DynamoDB |
| Secrets | Use AWS Secrets Manager / SSM |
| Modules | Reusable components |
| Workspaces | Environment separation |
| Tagging | Consistent resource tags |
| Validation | `terraform validate`, `tflint` |

## Common Commands

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
terraform state list
terraform import aws_instance.app i-1234567890
```
