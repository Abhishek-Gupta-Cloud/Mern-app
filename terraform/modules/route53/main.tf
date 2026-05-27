# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.zone_name

  tags = merge(var.tags, {
    Name = var.zone_name
  })
}

# Health Check for Primary Region
resource "aws_route53_health_check" "primary" {
  ip_address        = var.primary_alb_dns
  type              = "HTTP"
  port              = 80
  resource_path     = "/api/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.primary_region}-health-check"
  })
}

# Health Check for Secondary Region
resource "aws_route53_health_check" "secondary" {
  ip_address        = var.secondary_alb_dns
  type              = "HTTP"
  port              = 80
  resource_path     = "/api/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.secondary_region}-health-check"
  })
}

# Primary A Record with Failover
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.zone_name
  type    = "A"

  alias {
    name                   = var.primary_alb_dns
    zone_id                = "Z35SXDOTRQ7X7K"  # ALB Zone ID (adjust based on region)
    evaluate_target_health = true
  }

  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  depends_on = [aws_route53_zone.main]
}

# Secondary A Record with Failover
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.zone_name
  type    = "A"

  alias {
    name                   = var.secondary_alb_dns
    zone_id                = "Z1H1FL5HABSF5"   # ALB Zone ID (adjust based on region)
    evaluate_target_health = true
  }

  set_identifier = "Secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.secondary.id

  depends_on = [aws_route53_zone.main]
}

# CloudWatch Alarm for Primary Health Check
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  alarm_name          = "${var.zone_name}-primary-health-check"
  alarm_description   = "Alert when primary region health check fails"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  tags = var.tags
}

# CloudWatch Alarm for Secondary Health Check
resource "aws_cloudwatch_metric_alarm" "secondary_health" {
  alarm_name          = "${var.zone_name}-secondary-health-check"
  alarm_description   = "Alert when secondary region health check fails"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.secondary.id
  }

  tags = var.tags
}
