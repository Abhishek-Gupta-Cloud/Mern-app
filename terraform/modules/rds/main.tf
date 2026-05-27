# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "rds-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS"

  ingress {
    from_port   = var.db_engine == "mongodb" ? 27017 : (var.db_engine == "mysql" ? 3306 : 5432)
    to_port     = var.db_engine == "mongodb" ? 27017 : (var.db_engine == "mysql" ? 3306 : 5432)
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name_prefix = "rds-"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.db_instance_identifier}-subnet-group"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier            = var.db_instance_identifier
  engine                = var.db_engine == "mongodb" ? "docdb" : var.db_engine
  engine_version        = var.db_engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.db_engine == "mongodb" ? null : var.allocated_storage
  storage_type          = var.db_engine == "mongodb" ? null : "gp3"
  
  # Database configuration
  db_name  = var.db_engine == "mongodb" ? null : var.db_name
  username = "admin"
  password = random_password.db_password.result
  
  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup and maintenance
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  multi_az                = var.multi_az

  # Performance and monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Deletion protection
  deletion_protection = var.environment == "prod" || var.environment == "production"
  skip_final_snapshot = var.environment == "dev"
  
  final_snapshot_identifier = var.environment != "dev" ? "${var.db_instance_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # Tags
  tags = merge(var.tags, {
    Name = var.db_instance_identifier
  })

  depends_on = [aws_db_subnet_group.main]
}

# Generate random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "${var.db_instance_identifier}-password-"
  description = "Database password for ${var.db_instance_identifier}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = var.db_engine
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_engine == "mongodb" ? "admin" : var.db_name
  })
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.db_instance_identifier}"
  target_key_id = aws_kms_key.rds.key_id
}

# IAM Role for RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.db_instance_identifier}-high-cpu"
  alarm_description   = "Alert when RDS CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.db_instance_identifier}-low-storage"
  alarm_description   = "Alert when RDS storage is low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240  # 10 GB in bytes

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connection" {
  alarm_name          = "${var.db_instance_identifier}-high-connections"
  alarm_description   = "Alert when RDS connection count is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}
