output "zone_id" {
  description = "Route53 zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_nameservers" {
  description = "Route53 zone nameservers"
  value       = aws_route53_zone.main.name_servers
}

output "primary_record_fqdn" {
  description = "Primary record FQDN"
  value       = aws_route53_record.primary.fqdn
}

output "secondary_record_fqdn" {
  description = "Secondary record FQDN"
  value       = aws_route53_record.secondary.fqdn
}

output "primary_health_check_id" {
  description = "Primary health check ID"
  value       = aws_route53_health_check.primary.id
}

output "secondary_health_check_id" {
  description = "Secondary health check ID"
  value       = aws_route53_health_check.secondary.id
}
