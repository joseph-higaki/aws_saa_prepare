terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0.0"
      }
    }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "target_subnets" {
    filter {
      name= "availability-zone"
      values = var.target_azs # only the AZs selected in vars
    }
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
}


resource "aws_security_group" "ec2_sg" {
  name        = "ec2-instance-alb-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]    
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-http-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = data.aws_vpc.default.id

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

#   Aug 15 15:32
# max_price          = "0.0020" # Set your max bid price (optional)
# On-Demand price $0.0116 (0.0116 per vCPU)
# us-east-1a $0.0039 (0.0039 per vCPU)
# us-east-1b $0.0038 (0.0038 per vCPU)
# us-east-1c $0.0039 (0.0039 per vCPU)
# us-east-1d $0.0037 (0.0037 per vCPU)

# us-east-1e $0.0038 (0.0038 per vCPU)
# us-east-1f $0.0041(0.0041 per vCPU)     

# Hello world EC2 instances
resource "aws_launch_template" "app_lt_spot" {  
  name_prefix = "app-template-spot"
  image_id = var.ami
  instance_type = var.instance_type
  
  #key_name      = "ec2 tutorial"
  user_data     = filebase64("/workspaces/aws_saa_prepare/ec2-hello-world-user-data.sh")
  network_interfaces {    
    security_groups =  [aws_security_group.ec2_sg.id]
  }  
}



#create ASG
resource "aws_autoscaling_group" "app_asg_spot" {
  name_prefix = "app-asg"  
  desired_capacity     = 1
  max_size             = 5
  min_size             = 1  
  vpc_zone_identifier  = data.aws_subnets.target_subnets.ids
    
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.http_tg.arn]
    # Important for spot instances
  capacity_rebalance   = true # Automatically replace spot instances when interrupted

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_lt_spot.id
        version           = "$Latest"
      }

      # Specify multiple instance types for better spot availability
    #   override {
    #     instance_type     = "t3.micro"
    #   }
    #   override {
    #     instance_type     = "t3a.micro"
    #   }
    #   override {
    #     instance_type     = "t2.micro"
    #   }
    }

    instances_distribution {
      on_demand_base_capacity                  = 1 # All spot
      on_demand_percentage_above_base_capacity = 0 # 0% on-demand
      spot_allocation_strategy                 = "capacity-optimized" # Best practice
      #spot_max_price          = "0.0020" 
      # when spot_max_price 0.0020 the asg never outscaled
      # don't know where in the AWS GUI this is though hehe 
      spot_max_price          = "0.0040" # 0.004 is higher than Aug15 max price ref of 0.003x
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

# Add this new resource for CPU-based scaling
resource "aws_autoscaling_policy" "cpu_scaling_policy" {
  name                   = "cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app_asg_spot.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0  # Target 40% CPU utilization   
    
    disable_scale_in = false  # Allow both scale-out and scale-in
  }
}

# Create ALB target group
resource "aws_lb_target_group" "http_tg" {
  name     = "app-http-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
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
  subnets            = data.aws_subnets.target_subnets.ids
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
  value = aws_autoscaling_group.app_asg_spot.name
}