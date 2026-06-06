# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_dashboard ? 1 : 0
  dashboard_name = "${var.cluster_names[0]}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_node_count", { stat = "Average" }],
            ["AWS/EKS", "pod_count", { stat = "Average" }],
            ["AWS/EKS", "service_count", { stat = "Average" }],
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "EKS Overview"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            ["AWS/EC2", "NetworkIn", { stat = "Sum" }],
            ["AWS/EC2", "NetworkOut", { stat = "Sum" }],
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "Node Performance"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { stat = "Sum" }],
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "ALB Performance"
        }
      },
    ]
  })
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name_prefix = "eks-alerts-"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Group for Monitoring
resource "aws_cloudwatch_log_group" "monitoring" {
  name_prefix        = "/aws/eks/monitoring"
  retention_in_days  = 7

  tags = var.tags
}

# CloudWatch Alarms

# Primary EKS Cluster - Node CPU
resource "aws_cloudwatch_metric_alarm" "primary_node_cpu" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.cluster_names[0]}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when node CPU is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = var.tags
}

# Primary EKS Cluster - Pod Count
resource "aws_cloudwatch_metric_alarm" "primary_pod_count" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.cluster_names[0]}-pod-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PodCount"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Alert when pod count is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = var.tags
}

# Secondary EKS Cluster - Node CPU (if exists)
resource "aws_cloudwatch_metric_alarm" "secondary_node_cpu" {
  count               = var.enable_alarms && length(var.cluster_names) > 1 ? 1 : 0
  alarm_name          = "${var.cluster_names[1]}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when node CPU is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = var.tags
}

# Metric Filter for Errors in EKS Logs
resource "aws_cloudwatch_log_group" "eks_logs" {
  for_each = toset(var.cluster_names)

  name              = "/aws/eks/${each.value}/logs"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "eks_errors" {
  for_each = aws_cloudwatch_log_group.eks_logs

  name           = "${each.value.name}-errors"
  log_group_name = each.value.name
  pattern        = "[time, request_id, event_type = \"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "EKS"
    value     = "1"
  }
}

# CloudWatch Composite Alarm for Overall System Health
resource "aws_cloudwatch_composite_alarm" "system_health" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "mern-app-system-health"
  alarm_description   = "Overall system health across regions"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]

  alarm_rule = join(" OR ", concat(
    [aws_cloudwatch_metric_alarm.primary_node_cpu[0].alarm_name],
    length(var.cluster_names) > 1 ? [aws_cloudwatch_metric_alarm.secondary_node_cpu[0].alarm_name] : []
  ))

  tags = var.tags
}
