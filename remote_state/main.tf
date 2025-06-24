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

data "aws_caller_identity" "current" {}

module "terraform_state_bucket" {
  source            = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/s3-bucket-private?ref=main"
  bucket_name       = "terraform-state-bucket-${data.aws_caller_identity.current.account_id}-prod"
  account_number    = data.aws_caller_identity.current.account_id
  environment       = "prod"
  project           = "accountSetup"
  versioning_status = "Enabled"
  enable_acl        = false
  object_ownership  = "BucketOwnerEnforced"
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_bucket_lifecycle_config" {
  bucket = module.terraform_state_bucket.bucket_id

  rule {
    id      = "Expire old Terraform state files"
    status  = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 45
    }
  }
}