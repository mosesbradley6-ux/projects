output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}
