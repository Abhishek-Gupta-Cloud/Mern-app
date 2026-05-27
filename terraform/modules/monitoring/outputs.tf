output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = try(aws_cloudwatch_dashboard.main[0].dashboard_name, "")
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.alerts.name
}

output "log_group_names" {
  description = "CloudWatch log group names"
  value       = [for lg in aws_cloudwatch_log_group.eks_logs : lg.name]
}

output "primary_cpu_alarm_name" {
  description = "Primary CPU alarm name"
  value       = try(aws_cloudwatch_metric_alarm.primary_node_cpu[0].alarm_name, "")
}

output "composite_alarm_name" {
  description = "Composite system health alarm name"
  value       = try(aws_cloudwatch_composite_alarm.system_health[0].alarm_name, "")
}
