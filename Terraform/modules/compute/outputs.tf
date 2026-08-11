output "load_balancer_dns_name" {
  value = aws_lb.this.dns_name
}

output "load_balancer_arn" {
  value = aws_lb.this.arn
}
