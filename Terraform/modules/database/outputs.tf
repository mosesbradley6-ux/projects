output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "db_identifier" {
  value = aws_db_instance.this.id
}
