terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0.0"
      }
    }
}

# Get current AWS account ID
#data "aws_caller_identity" "current" {}

#resource "aws_s3_bucket" "test_bucket" {
  #bucket = "${data.aws_caller_identity.current.account_id}-test-bucket-123"  # Unique name
#}


resource "aws_security_group" "ec2_sg" {
  name        = "ec2-instance-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = "vpc-08f1f38433b726df1"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_instance" "ec2_instances" {
  count         = 2
  ami           = "ami-0cbbe2c6a1bb2ad63"  # al2023-ami-2023.8.20250715.0-kernel-6.1-x86_64
  instance_type = "t2.micro"
  subnet_id     = "subnet-0fac88ae09f20fd66"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile = "DemoRoleEC2"
  key_name      = "ec2 tutorial"
  user_data     = file("/workspaces/aws_saa_prepare/ec2-user-data.sh")

  tags = {
    Name = "ec2-instance-${count.index + 1}"
  }
}

output "instance_public_ips" {
  value = aws_instance.ec2_instances[*].public_ip
}