variable "region" {
  type        = string
  description = "Region"
  default     = "us-east-1"
}

variable "bucket" {
  type        = string
  description = "Your VPC ID"
  default     = "terraform"
}

variable "instance_type" {
  type        = string
  description = "Your VPC ID"
  default     = "t2.medium"
}

variable "domain_name" {
  type        = string
  description = "Your VPC ID"
  default     = "backstage.aws.com"
}