resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags = var.tags
}

resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "${var.name}-mysql-params"
  family = "mysql8.0"
  tags   = merge(var.tags, { Name = "${var.name}-mysql-params" })
}

# Fetch secret from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = var.secret_id
}

# Decode JSON secret
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_instance" "web_app_db" {
  identifier = var.db_name
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = local.db_creds["username"]
  password             = local.db_creds["password"]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az             = var.multi_az
  skip_final_snapshot  = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_days
  deletion_protection        = var.deletion_protection
  parameter_group_name       = aws_db_parameter_group.db_parameter_group.name
  publicly_accessible        = var.publicly_accessible
  storage_encrypted          = var.storage_encrypted
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  tags = var.tags
}

output "endpoint" { 
    value = aws_db_instance.web_app_db.endpoint
    }

output "address" { 
    value = aws_db_instance.web_app_db.address 
    }

output "port" { 
    value = aws_db_instance.web_app_db.port 
    }
