terraform {
  backend "s3" {
    bucket = "<your-bucket-name>"
    key    = "assignment-1/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# todo: create a security group that allows inbound HTTP on port 80

# todo: create an ec2 instance using the ami, security group, and init-mp.yaml as user data
