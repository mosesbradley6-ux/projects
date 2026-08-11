output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.networking.vpc_id
}

output "web_alb_dns_name" {
  description = "Public DNS name of the web tier ALB - browse to this to reach the app"
  value       = module.web_tier.alb_dns_name
}

output "app_alb_dns_name" {
  description = "Internal DNS name of the app tier ALB (only reachable from inside the VPC)"
  value       = module.app_tier.alb_dns_name
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.database.db_endpoint
  sensitive   = true
}
