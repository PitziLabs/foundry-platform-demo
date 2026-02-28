terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "aws-lab"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "aws-lab"
      ManagedBy   = "terraform"
    }
  }
}
