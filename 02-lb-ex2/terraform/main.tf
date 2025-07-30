terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0.0"
      }
    }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-instance-alb-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]    
  }

  # nO SSH
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-http-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Hello world EC2 instances
resource "aws_instance" "ec2_instances" {
  count         = 2
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id_az_d
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile = "DemoRoleEC2"
  key_name      = "ec2 tutorial"
  user_data     = file("/workspaces/aws_saa_prepare/ec2-hello-world-user-data.sh")

  tags = {
    Name = "ec2-instance-alb-${count.index + 1}"
  }
}

# Create ALB target group
resource "aws_lb_target_group" "http_tg" {
  name     = "http-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create the special error EC2 instance
resource "aws_instance" "special_error_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id_az_d
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = "DemoRoleEC2"
  key_name               = "ec2 tutorial"
  user_data     = file("/workspaces/aws_saa_prepare/ec2-error-user-data.sh")

  tags = {
    Name = "special-error-instance"
  }
}

# Create a new target group for the special error instance
resource "aws_lb_target_group" "special_error_tg" {
  name     = "special-error-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach EC2 instances to target group
resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = length(aws_instance.ec2_instances)
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = aws_instance.ec2_instances[count.index].id
  port             = 80
}

# Attach the special error instance to its target group
resource "aws_lb_target_group_attachment" "special_error_attachment" {
  target_group_arn = aws_lb_target_group.special_error_tg.arn
  target_id        = aws_instance.special_error_instance.id
  port             = 80
}

# Create ALB
resource "aws_lb" "http_alb" {
  name               = "http-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.subnet_id_az_d, var.subnet_id_az_e] # You might want to add another subnet for high availability
  enable_deletion_protection = false
}

# Create ALB listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.http_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }
}

# Add listener rules
resource "aws_lb_listener_rule" "error_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 100

  action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "not found"
      status_code  = "404"
    }
  }
  condition {
    path_pattern {
      values = ["/error"]
    }
  }
}

resource "aws_lb_listener_rule" "special_error_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.special_error_tg.arn
  }

  condition {
    path_pattern {
      values = ["/special_error.html"]
    }
  }
}

output "instance_public_ips" {
  value = aws_instance.ec2_instances[*].public_ip
}

output "alb_dns_name" {
  value = aws_lb.http_alb.dns_name
}