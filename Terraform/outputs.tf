output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnets" {
  value = module.network.public_subnet_ids
}

output "private_app_subnets" {
  value = module.network.private_app_subnet_ids
}

output "database_subnets" {
  value = module.network.database_subnet_ids
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "database_endpoint" {
  value = module.database.endpoint
}

output "load_balancer_dns_name" {
  value = module.compute.load_balancer_dns_name
}
