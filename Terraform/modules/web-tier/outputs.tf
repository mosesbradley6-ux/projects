output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "instance_security_group_id" {
  value = aws_security_group.web.id
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}
