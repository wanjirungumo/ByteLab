variable "aws_region" {
  description = "AWS region where the lab is deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used in resource names"
  type        = string
  default     = "lab-cloudsec"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR of the public subnet (WAF instance and NAT Gateway)"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR of the private subnet (Juice Shop and Wazuh instances)"
  type        = string
  default     = "10.10.2.0/24"
}

variable "admin_cidrs" {
  description = "Public IPs of the team allowed to SSH into the WAF, e.g. [\"203.0.113.10/32\"]"
  type        = list(string)
}
