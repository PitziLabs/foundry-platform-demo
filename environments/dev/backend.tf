terraform {
  backend "s3" {
    bucket         = "aws-lab-tfstate-365184644049" # Account-specific — see docs/BOOTSTRAP.md
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-lab-tfstate-lock"
    encrypt        = true
  }
}
