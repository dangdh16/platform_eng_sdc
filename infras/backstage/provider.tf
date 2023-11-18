terraform {
  backend "s3" {
    bucket = "terraformstate-dang1"
    key    = "dangtest"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.region
}