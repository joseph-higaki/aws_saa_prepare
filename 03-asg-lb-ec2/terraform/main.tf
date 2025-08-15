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
resource "aws_launch_template" "app_lt" {  
  name_prefix = "app-template-"
  image_id = var.ami
  instance_type = var.instance_type
  iam_instance_profile {
    name = "DemoRoleEC2"
  }  
  key_name      = "ec2 tutorial"
  user_data     = filebase64("/workspaces/aws_saa_prepare/ec2-hello-world-user-data.sh")
  network_interfaces {    
    security_groups =  [aws_security_group.ec2_sg.id]
  }  
}

#create ASG
resource "aws_autoscaling_group" "app_asg" {
  name_prefix = "app-asg"  
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = [var.subnet_id_az_d, var.subnet_id_az_e]
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.http_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

# Create ALB target group
resource "aws_lb_target_group" "http_tg" {
  name     = "app-http-target-group"
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


output "alb_dns_name" {
  value = aws_lb.http_alb.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}