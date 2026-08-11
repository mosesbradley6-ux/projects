output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.internal_alb.id
}

output "instance_security_group_id" {
  value = aws_security_group.app.id
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}
