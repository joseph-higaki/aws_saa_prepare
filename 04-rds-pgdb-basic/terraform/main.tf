# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-postgres-sg"
  description = "Allow PostgreSQL access from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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
    Name = "rds-postgres-security-group"
  }
}

# PostgreSQL RDS Instance
resource "aws_db_instance" "postgres" {
  identifier             = "postgres-db-what-is-this-identifier"
  engine                 = "postgres"
  engine_version         = "15.8" # Latest stable PostgreSQL version
  instance_class         = var.rds_instance_type
  allocated_storage      = 20
  storage_type           = "gp2"
  max_allocated_storage  = 500 # Enable storage autoscaling up to 500 GiB
  storage_encrypted      = false
  
  # Database credentials
  username               = "postgres" # Default PostgreSQL admin user
  password               = "postgres" # Yes, this is not prod ready
  publicly_accessible    = true
  
  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  # db_subnet_group_name   = aws_db_subnet_group.default.name
  
  # Database configuration
  # name                   = "postgres" # Default database name
  parameter_group_name   = "default.postgres15"
  skip_final_snapshot    = true # Allow deletion without final snapshot
  
  # Disable features as specified
  backup_retention_period = 0      # Disable automatic backups
  monitoring_interval     = 0      # Disable enhanced monitoring
  deletion_protection     = false  # Disable deletion protection
  
  # Performance Insights (optional, but good to specify)
  performance_insights_enabled = false
  
  tags = {
    Name = "postgres-rds-instance"
  }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "target_subnets" {
    filter {
      name= "availability-zone"
      values = var.target_azs # only the AZs selected in vars
    }
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
}

# Output the database connection details
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "rds_username" {
  description = "The master username for the database"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "rds_password" {
  description = "The master password for the database"
  value       = aws_db_instance.postgres.password
  sensitive   = true
}

output "rds_database_identifier" {
  description = "The name of the default database"
  value       = aws_db_instance.postgres.identifier
}