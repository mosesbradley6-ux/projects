data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.project_name}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.web_sg_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl enable --now httpd
    cat > /var/www/html/index.html <<'HTML'
    <!doctype html>
    <html>
      <head><title>Terraform 3-Tier Demo</title></head>
      <body>
        <h1>Terraform 3-Tier Test Application</h1>
        <p>ALB -> Application/Web Tier -> Database Tier</p>
        <p>Infrastructure created with Terraform modules.</p>
      </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-web"
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.project_name}-asg"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.this.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
}
