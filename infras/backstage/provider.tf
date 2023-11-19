terraform {
  backend "s3" {
    bucket = "terraform-backstage-dang"
    key    = "backstage"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.region
}