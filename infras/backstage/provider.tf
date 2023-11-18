terraform {
  backend "s3" {
    bucket = "terraformstate-dang"
    key    = "dangtest"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.region
}