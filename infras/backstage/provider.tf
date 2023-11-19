terraform {
  backend "s3" {
    bucket = "terraform-backstage-dangdong"
    key    = "backstage"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.region
}