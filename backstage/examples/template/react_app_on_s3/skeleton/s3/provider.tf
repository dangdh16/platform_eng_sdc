provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }

  backend "s3" {
    bucket  = "hieu-backstage-tfstate"
    key     = "${{ values.component_id }}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = false
  }
}