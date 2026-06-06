output "cluster_id" {
  description = "DocumentDB cluster identifier"
  value       = aws_docdb_cluster.main.id
}

output "cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
  sensitive   = true
}

output "reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.main.reader_endpoint
  sensitive   = true
}

output "cluster_port" {
  description = "DocumentDB cluster port"
  value       = aws_docdb_cluster.main.port
}

output "secret_arn" {
  description = "Secrets Manager ARN storing DocumentDB credentials"
  value       = aws_secretsmanager_secret.documentdb_credentials.arn
  sensitive   = true
}

output "secret_name" {
  description = "Secrets Manager secret name for DocumentDB credentials"
  value       = aws_secretsmanager_secret.documentdb_credentials.name
  sensitive   = true
}

output "mongo_uri" {
  description = "DocumentDB connection string for MongoDB clients"
  value       = "mongodb://${var.documentdb_username}:${urlencode(random_password.documentdb_password.result)}@${aws_docdb_cluster.main.endpoint}:${aws_docdb_cluster.main.port}/${var.documentdb_database_name}?authSource=admin&ssl=true&retryWrites=false"
  sensitive   = true
}

output "documentdb_username" {
  description = "DocumentDB username"
  value       = var.documentdb_username
}

output "documentdb_password" {
  description = "DocumentDB password"
  value       = random_password.documentdb_password.result
  sensitive   = true
}
