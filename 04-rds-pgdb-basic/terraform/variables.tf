variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true  # Marks the value as sensitive in outputs
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "rds_instance_type" {
  description = "instance type to use on ec2 instances"
  type        = string
  default     = "db.t3.micro"
}

variable "target_azs" {
  type    = list(string)
  default = ["us-east-1a"]
}