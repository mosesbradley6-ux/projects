resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_name}-postgres"
  engine                 = "postgres"
  engine_version         = "17"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 50
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_sg_id]

  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  multi_az               = false

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
