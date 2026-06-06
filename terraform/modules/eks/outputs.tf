output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data from the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.cluster.id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, "")
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_asg_name" {
  description = "Auto Scaling Group name for node group"
  value       = aws_eks_node_group.main.resources[0].autoscaling_groups[0].name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = try(aws_eks_node_group.main.resources[0].autoscaling_groups[0].name, "")
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = try(aws_lb.main[0].dns_name, "")
}

output "alb_arn" {
  description = "ALB ARN"
  value       = try(aws_lb.main[0].arn, "")
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = try(aws_lb.main[0].zone_id, "")
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for ALB controller"
  value       = aws_iam_role.alb_controller.arn
}
