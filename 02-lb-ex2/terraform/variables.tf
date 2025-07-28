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

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
  default     = "vpc-08f1f38433b726df1"
}

variable "subnet_id_az_d" {
  description = "The ID of the subnet"
  type        = string
  default     = "subnet-0fac88ae09f20fd66"
}

variable "subnet_id_az_e" {
  description = "The ID of the subnet"
  type        = string
  default     = "subnet-0347f477e44b8c202"
}
