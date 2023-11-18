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

# variable "vpc_id" {
#   type        = string
#   description = "Your VPC ID"
#   default     = "vpc-0eb0772fd54a5c5e3"
# }

variable "instance_type" {
  type        = string
  description = "Your VPC ID"
  default     = "t2.medium"
}