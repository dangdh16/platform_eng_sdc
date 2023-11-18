data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# tolist(data.aws_subnet_ids.default.ids)[0]
# data "aws_vpc" "selected" {
#   filter {
#     name   = "isDefault"
#     values = [true]
#   }
# }

# data "aws_subnet" "subneta" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.selected.id]
#   }
#   tags = {
#     Name = "webapp-subnet-a"
#   }
# }

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"]
  }
  owners = ["099720109477"]
}