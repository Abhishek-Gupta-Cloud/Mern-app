output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = try(aws_cloudwatch_dashboard.main[0].dashboard_name, "")
}

output "dashboard_url" {
  description = "CloudWatch dashboard console URL"
  value       = try("https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}", "")
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.alerts.name
}

output "log_group_name" {
  description = "CloudWatch log group name for EKS monitoring"
  value       = try(aws_cloudwatch_log_group.monitoring[0].name, "")
}

output "node_cpu_alarm_names" {
  description = "Names of node CPU alarms"
  value       = [for a in values(aws_cloudwatch_metric_alarm.node_cpu) : a.alarm_name]
}

output "node_memory_alarm_names" {
  description = "Names of node memory alarms"
  value       = [for a in values(aws_cloudwatch_metric_alarm.node_memory) : a.alarm_name]
}

output "alb_5xx_alarm_name" {
  description = "ALB 5XX error alarm name"
  value       = try(aws_cloudwatch_metric_alarm.alb_5xx[0].alarm_name, "")
}

output "alb_latency_alarm_name" {
  description = "ALB latency alarm name"
  value       = try(aws_cloudwatch_metric_alarm.alb_latency[0].alarm_name, "")
}

output "eks_node_failure_alarm_name" {
  description = "EKS node failure alarm name"
  value       = try(aws_cloudwatch_metric_alarm.eks_node_failure[0].alarm_name, "")
}

output "composite_alarm_name" {
  description = "Composite system health alarm name"
  value       = try(aws_cloudwatch_composite_alarm.system_health[0].alarm_name, "")
}
