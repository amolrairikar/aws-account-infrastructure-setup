terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-2"
  assume_role {
    role_arn     = var.infra_role_arn
    session_name = "terraform-session"
  }
}

module "terraform_state_bucket" {
  source         = "../modules/s3-bucket-private"
  bucket_prefix  = "terraform-state-bucket"
  account_number = var.account_number
  environment    = "prod"
  project        = "accountSetup"
}

output "s3_bucket_name" {
  value = module.terraform_state_bucket.bucket_id
}

output "s3_bucket_arn" {
  value = module.terraform_state_bucket.bucket_arn
}