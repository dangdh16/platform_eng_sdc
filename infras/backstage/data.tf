data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "subneta" {
  vpc_id     = data.aws_vpc.default.id
  depends_on = [data.aws_vpc.default]

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}

data "aws_subnet" "subnetb" {
  vpc_id     = data.aws_vpc.default.id
  depends_on = [data.aws_vpc.default]

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"]
  }
  owners = ["099720109477"]
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}