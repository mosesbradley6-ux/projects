# NOTE: No `data "aws_ssm_parameter" "amazon_linux_2" {}` here on purpose.
# In sandbox/training accounts, ssm:GetParameter is sometimes explicitly
# denied by an org-level SCP, which breaks the usual "latest AMI" lookup.
# Instead we take the AMI ID as an input variable from root (var.ami_id).

# --- Security groups ---

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-app-alb-sg"
  description = "Internal app ALB - allow app_port from web tier instances only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from web tier"
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
}

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-app-instance-sg"
  description = "App tier instances - allow app_port from app ALB, SSH from allowed CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from app ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
}

# --- Internal ALB ---

resource "aws_lb" "app" {
  name               = "${var.project_name}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
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

# --- Launch template + ASG ---
# Placeholder app: a trivial Python HTTP server on var.app_port. Swap this
# user_data for your real deployment method (AMI baked with your app,
# CodeDeploy, containers, etc) before using this beyond a quick test.

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    mkdir -p /opt/app
    cat > /opt/app/app.py <<'PY'
    import http.server
    import socketserver

    PORT = ${var.app_port}

    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK from ${var.project_name} app tier\n")

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.serve_forever()
    PY
    cat > /etc/systemd/system/sampleapp.service <<'UNIT'
    [Unit]
    Description=Sample app tier service
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/app/app.py
    Restart=always
    User=ec2-user

    [Install]
    WantedBy=multi-user.target
    UNIT
    systemctl daemon-reload
    systemctl enable sampleapp
    systemctl start sampleapp
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}
