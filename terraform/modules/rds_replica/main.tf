# RDS Read Replica
resource "aws_db_instance" "read_replica" {
  # Count-based approach for read replica
  identifier             = var.replica_identifier
  replicate_source_db    = var.source_db_identifier
  instance_class         = var.instance_class
  publicly_accessible    = false
  auto_minor_version_upgrade = true
  
  # Replication settings
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.replica_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Encryption (inherited from source)
  storage_encrypted = true

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_replica_monitoring.arn

  # Deletion protection
  deletion_protection = var.environment == "prod" || var.environment == "production"

  tags = merge(var.tags, {
    Name = var.replica_identifier
    Type = "ReadReplica"
  })
}

# IAM Role for RDS replica monitoring
resource "aws_iam_role" "rds_replica_monitoring" {
  name_prefix = "rds-replica-monitoring-"

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

resource "aws_iam_role_policy_attachment" "rds_replica_monitoring" {
  role       = aws_iam_role.rds_replica_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for Read Replica
resource "aws_cloudwatch_metric_alarm" "replica_replication_lag" {
  alarm_name          = "${var.replica_identifier}-replication-lag"
  alarm_description   = "Alert when replication lag is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraBinlogReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 1000  # milliseconds

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica.id
  }

  tags = var.tags
}
