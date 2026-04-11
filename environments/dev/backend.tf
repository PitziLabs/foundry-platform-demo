terraform {
  backend "s3" {
    bucket         = "foundry-tfstate-365184644049" # Account-specific — see docs/BOOTSTRAP.md
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "foundry-tfstate-lock"
    encrypt        = true
  }
}
