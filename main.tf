terraform {
  backend "s3" {}
}

provider "aws" {
  region = "us-east-2"
  assume_role {
    role_arn     = var.infra_role_arn
    session_name = "terraform-session"
  }
}

module "sns_email_subscription" {
  source         = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/sns-email-subscription?ref=main"
  sns_topic_name = "lambda-failure-notification-topic"
  user_email     = var.email
  environment    = var.environment
  project        = var.project
}