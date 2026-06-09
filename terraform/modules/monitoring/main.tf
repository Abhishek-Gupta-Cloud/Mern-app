locals {
  alb_name = data.aws_lb.app.name

  node_cpu_metrics = [
  for asg in var.autoscaling_group_names : [
    "AWS/EC2",
    "CPUUtilization",
    "AutoScalingGroupName",
    asg,
    {
      stat = "Average"
    }
    ] 
    ]

 node_memory_metrics = [
  for asg in var.autoscaling_group_names : [
    "CWAgent",
    "mem_used_percent",
    "AutoScalingGroupName",
    asg,
    {
      stat = "Average"
    }
  ]
]

  dashboard_widgets = [
    for widget in [
      var.enable_node_alarms && length(local.node_cpu_metrics) > 0 ? {
        type = "metric"
        properties = {
          metrics = local.node_cpu_metrics
          period  = var.dashboard_widget_period
          stat    = "Average"
          region  = var.aws_region
          title   = "Node CPU Utilization"
        }
      } : null,

      var.enable_memory_metrics && var.enable_node_alarms && length(local.node_memory_metrics) > 0 ? {
        type = "metric"
        properties = {
          metrics = local.node_memory_metrics
          period  = var.dashboard_widget_period
          stat    = "Average"
          region  = var.aws_region
          title   = "Node Memory Utilization"
        }
      } : null,

      var.enable_alb_alarms ? {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", dimensions = { LoadBalancer = local.alb_name } }],
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", dimensions = { LoadBalancer = local.alb_name } }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { stat = "Sum", dimensions = { LoadBalancer = local.alb_name } }]
          ]
          period = var.dashboard_widget_period
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Performance"
        }
      } : null,

      var.enable_eks_health_metrics ? {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "FailedNodeCount", { stat = "Maximum", dimensions = { ClusterName = var.cluster_name } }],
            ["AWS/EKS", "NodeCount", { stat = "Maximum", dimensions = { ClusterName = var.cluster_name } }]
          ]
          period = var.dashboard_widget_period
          stat   = "Maximum"
          region = var.aws_region
          title  = "EKS Cluster Health"
        }
      } : null
    ] : widget
    if widget != null
  ]
}

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_dashboard ? 1 : 0
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = local.dashboard_widgets
  })
}

data "aws_lb" "app" {
  arn = var.alb_arn
}

resource "aws_sns_topic" "alerts" {
  name_prefix = "eks-alerts-"
  tags        = var.tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.enable_alarms ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_log_group" "monitoring" {
  count             = var.enable_log_monitoring ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/monitoring"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "eks_errors" {
  count          = var.enable_log_monitoring ? 1 : 0
  name           = "${var.cluster_name}-error-count"
  log_group_name = aws_cloudwatch_log_group.monitoring[0].name
  pattern        = "?ERROR ?Error ?Exception ?exception"

  metric_transformation {
    name      = "EKSLogErrorCount"
    namespace = "EKS"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "node_cpu" {
  for_each = (
  var.enable_alarms &&
  var.enable_node_alarms
) ? {
  for idx, asg in var.autoscaling_group_names :
  tostring(idx) => asg
} : {}

  alarm_name          = "${var.cluster_name}-${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "EKS node CPU usage above ${var.alarm_cpu_threshold}% for ASG ${each.key}"
  alarm_actions       = var.alarm_actions_enabled ? [aws_sns_topic.alerts.arn] : []
  dimensions = {
    AutoScalingGroupName = each.value
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "node_memory" {
  for_each = (
  var.enable_alarms &&
  var.enable_node_alarms &&
  var.enable_memory_metrics
) ? {
  for idx, asg in var.autoscaling_group_names :
  tostring(idx) => asg
} : {}

  alarm_name          = "${var.cluster_name}-${each.key}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold
  alarm_description   = "EKS node memory usage above ${var.alarm_memory_threshold}% for ASG ${each.key}"
  alarm_actions       = var.alarm_actions_enabled ? [aws_sns_topic.alerts.arn] : []
  dimensions = {
    AutoScalingGroupName = each.value
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.enable_alarms && var.enable_alb_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.alarm_5xx_threshold
  alarm_description   = "ALB 5XX errors exceed threshold"
  alarm_actions       = var.alarm_actions_enabled ? [aws_sns_topic.alerts.arn] : []
  dimensions = {
    LoadBalancer = local.alb_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  count               = var.enable_alarms && var.enable_alb_alarms ? 1 : 0
  alarm_name          = "${var.cluster_name}-alb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_latency_threshold
  alarm_description   = "ALB target response time is above threshold"
  alarm_actions       = var.alarm_actions_enabled ? [aws_sns_topic.alerts.arn] : []
  dimensions = {
    LoadBalancer = local.alb_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "eks_node_failure" {
  count               = var.enable_alarms && var.enable_node_failure_alarm && var.enable_eks_health_metrics ? 1 : 0
  alarm_name          = "${var.cluster_name}-eks-node-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedNodeCount"
  namespace           = "AWS/EKS"
  period              = var.alarm_period
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "EKS cluster failed node count is greater than or equal to 1"
  alarm_actions       = var.alarm_actions_enabled ? [aws_sns_topic.alerts.arn] : []
  dimensions = {
    ClusterName = var.cluster_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_composite_alarm" "system_health" {
  count             = var.enable_alarms && var.enable_composite_alarm ? 1 : 0
  alarm_name        = "${var.cluster_name}-system-health"
  alarm_description = "Composite system health alarm for the EKS cluster"
  actions_enabled   = var.alarm_actions_enabled
  alarm_actions     = var.alarm_actions_enabled ? [aws_sns_topic.alerts.arn] : []

    alarm_rule = join(" OR ", compact(concat(
    var.enable_node_alarms ? [
      for a in values(aws_cloudwatch_metric_alarm.node_cpu) :
      "ALARM(\"${a.alarm_name}\")"
    ] : [],

    var.enable_node_alarms && var.enable_memory_metrics ? [
      for a in values(aws_cloudwatch_metric_alarm.node_memory) :
      "ALARM(\"${a.alarm_name}\")"
    ] : [],

    var.enable_alb_alarms ? [
      for a in aws_cloudwatch_metric_alarm.alb_5xx :
      "ALARM(\"${a.alarm_name}\")"
    ] : [],

    var.enable_alb_alarms ? [
      for a in aws_cloudwatch_metric_alarm.alb_latency :
      "ALARM(\"${a.alarm_name}\")"
    ] : [],

    var.enable_node_failure_alarm ? [
      for a in aws_cloudwatch_metric_alarm.eks_node_failure :
      "ALARM(\"${a.alarm_name}\")"
    ] : []
  )))

  tags = var.tags
}
