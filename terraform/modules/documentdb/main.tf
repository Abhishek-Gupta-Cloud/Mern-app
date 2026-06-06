terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

resource "aws_security_group" "documentdb" {
  name_prefix = "${var.cluster_identifier}-documentdb-"
  vpc_id      = var.vpc_id
  description = "DocumentDB security group for ${var.cluster_identifier}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-documentdb-sg"
  })
}

resource "aws_security_group_rule" "allow_from_eks_security_groups" {
  count = length(var.eks_security_group_ids) > 0 ? length(var.eks_security_group_ids) : 0

  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.documentdb.id
  source_security_group_id = var.eks_security_group_ids[count.index]
}

resource "aws_security_group_rule" "allow_from_private_cidr" {
  count = length(var.eks_security_group_ids) == 0 ? length(var.private_cidr_blocks) : 0

  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = [var.private_cidr_blocks[count.index]]
  security_group_id = aws_security_group.documentdb.id
}

resource "aws_docdb_subnet_group" "main" {
  name_prefix = "${var.cluster_identifier}-"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-subnet-group"
  })
}

resource "aws_docdb_cluster_parameter_group" "main" {
  name_prefix = "${var.cluster_identifier}-"
  family      = var.parameter_group_family
  description = "DocumentDB cluster parameter group for ${var.cluster_identifier}"

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-parameter-group"
  })
}

resource "random_password" "documentdb_password" {
  length           = 32
  special          = true
  override_special = "@#$%&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "documentdb_credentials" {
  name_prefix = "${var.cluster_identifier}-credentials-"
  description = "DocumentDB credentials for ${var.cluster_identifier}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "documentdb_credentials" {
  secret_id = aws_secretsmanager_secret.documentdb_credentials.id
  secret_string = jsonencode({
    username = var.documentdb_username
    password = random_password.documentdb_password.result
    host     = aws_docdb_cluster.main.endpoint
    port     = aws_docdb_cluster.main.port
    database = var.documentdb_database_name
    uri      = "mongodb://${var.documentdb_username}:${urlencode(random_password.documentdb_password.result)}@${aws_docdb_cluster.main.endpoint}:${aws_docdb_cluster.main.port}/${var.documentdb_database_name}?authSource=admin&ssl=true&retryWrites=false"
  })
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = var.cluster_identifier
  engine                          = "docdb"
  engine_version                  = var.documentdb_engine_version
  master_username                 = var.documentdb_username
  master_password                 = random_password.documentdb_password.result
  backup_retention_period         = var.documentdb_backup_retention_period
  preferred_backup_window         = var.documentdb_preferred_backup_window
  preferred_maintenance_window    = var.documentdb_preferred_maintenance_window
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.documentdb.id]
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  apply_immediately               = true
  deletion_protection             = var.environment == "prod" || var.environment == "production"
  skip_final_snapshot             = var.environment == "dev"
  storage_encrypted               = true

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}"
  })
}

resource "aws_docdb_cluster_instance" "instances" {
  count                = var.instance_count
  identifier           = "${var.cluster_identifier}-instance-${count.index + 1}"
  cluster_identifier             = aws_docdb_cluster.main.id
  instance_class                 = var.documentdb_instance_class
  engine                         = "docdb"
  auto_minor_version_upgrade     = true
  apply_immediately              = false

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-instance-${count.index + 1}"
  })
}

resource "aws_cloudwatch_metric_alarm" "docdb_cpu" {
  alarm_name          = "${var.cluster_identifier}-high-cpu"
  alarm_description   = "Alert when DocumentDB CPU usage is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "docdb_connections" {
  alarm_name          = "${var.cluster_identifier}-high-connections"
  alarm_description   = "Alert when DocumentDB connection count is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 100

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "docdb_storage" {
  alarm_name          = "${var.cluster_identifier}-high-storage"
  alarm_description   = "Alert when DocumentDB storage usage is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "VolumeBytesUsed"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 85899345920

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "docdb_replication_lag" {
  alarm_name          = "${var.cluster_identifier}-replication-lag"
  alarm_description   = "Alert when DocumentDB replication lag is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLag"
  namespace           = "AWS/DocDB"
  period              = 60
  statistic           = "Average"
  threshold           = 1000

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.id
  }

  tags = var.tags
}
