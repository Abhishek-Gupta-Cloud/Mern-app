output "db_instance_id" {
  description = "Read replica instance ID"
  value       = aws_db_instance.read_replica.id
}

output "db_endpoint" {
  description = "Read replica endpoint"
  value       = aws_db_instance.read_replica.endpoint
  sensitive   = true
}

output "db_address" {
  description = "Read replica address"
  value       = aws_db_instance.read_replica.address
}

output "db_port" {
  description = "Read replica port"
  value       = aws_db_instance.read_replica.port
}

output "replication_lag_alarm_name" {
  description = "CloudWatch alarm name for replication lag"
  value       = aws_cloudwatch_metric_alarm.replica_replication_lag.alarm_name
}
