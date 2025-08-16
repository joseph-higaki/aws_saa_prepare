provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0.0"
      }
    }
}

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

data "aws_vpc" "default" {
  default = true  # Explicitly look for the default VPC
}

# output "default_vpc_id" {
#   value = data.aws_vpc.default.id
# }

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# output "default_subnet_ids" {
#   value = data.aws_subnets.default_subnets.ids
# }

data "aws_availability_zones" "available" {
  state = "available"
}
# output "availability_zones_ids" {
#   value = data.aws_availability_zones.available.names
# }

# This object becomes a map
# key : az
# value: aws_subnet object
data "aws_subnet" "default_subnets_by_az" {
  for_each = toset(data.aws_availability_zones.available.names) #you can also hardcode desired AZs
  vpc_id = data.aws_vpc.default.id
  availability_zone = each.key
}

# Cannot access it
# vpc_zone_identifier = [data.aws_subnet.default_subnets_by_az.id]  # Wrong!

# should be
# vpc_zone_identifier = [for subnet in data.aws_subnet.default_subnets_by_az : subnet.id]

output "default_subnets_by_az" {
  value = {
    for az, subnet in data.aws_subnet.default_subnets_by_az : az => subnet.id
  }
}

output "default_subnets_us-east-1b" {
  value = data.aws_subnet.default_subnets_by_az["us-east-1b"].id
}

locals {
  # Most explicit form - recommended
  subnet_ids = [for subnet in values(data.aws_subnet.default_subnets_by_az) : subnet.id]
  
  # Equivalent alternatives
  subnet_ids_alt1 = [for s in data.aws_subnet.default_subnets_by_az : s.id]
  subnet_ids_alt2 = [for az, s in data.aws_subnet.default_subnets_by_az : s.id]
}

output "local_subnet_ids_alt1_all_equivalent" {
  value = local.subnet_ids_alt1          
}

output "local_subnet_ids_alt2_all_equivalent" {
  value = local.subnet_ids_alt2
}