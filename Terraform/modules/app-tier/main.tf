data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gebs"
}

# --- Security Groups ---

resource "aws_security_group" "internal_alb" {
  name_prefix = "${var.project_name}-app-alb-"
  description = "Allow inbound app port from web tier only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from web tier instances"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.web_instance_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-instance-"
  description = "Allow app port from internal ALB and SSH from allowed CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from internal ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-instance-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- Internal ALB ---

resource "aws_lb" "app" {
  name               = "${var.project_name}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = var.app_subnet_ids

  tags = {
    Name = "${var.project_name}-app-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- Launch Template + Auto Scaling Group ---

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.app.id]

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install -y python3.8 2>/dev/null || yum install -y python3
    cat <<'PYEOF' > /home/ec2-user/app.py
    import http.server, socketserver, socket
    PORT = ${var.app_port}
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"App tier OK - {socket.gethostname()}".encode())
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.serve_forever()
    PYEOF
    nohup python3 /home/ec2-user/app.py > /var/log/app.log 2>&1 &
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix               = "${var.project_name}-app-"
  desired_capacity           = var.asg_desired_capacity
  min_size                   = var.asg_min_size
  max_size                   = var.asg_max_size
  vpc_zone_identifier        = var.app_subnet_ids
  target_group_arns          = [aws_lb_target_group.app.arn]
  health_check_type          = "ELB"
  health_check_grace_period  = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
