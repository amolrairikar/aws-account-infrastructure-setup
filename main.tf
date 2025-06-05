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

data "aws_iam_policy_document" "infra_role_trust_relationship_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.terraform_user_arn]
    }
  }
}

data "aws_iam_policy_document" "infra_role_inline_policy_document" {
  statement {
    effect    = "Allow"
    actions   = [
      "scheduler:CreateSchedule",
      "scheduler:UpdateSchedule",
      "scheduler:DeleteSchedule",
      "scheduler:GetSchedule",
      "scheduler:ListSchedules"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:PutFunctionEventInvokeConfig",
      "lambda:DeleteFunctionEventInvokeConfig",
      "lambda:GetFunctionEventInvokeConfig",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketTagging",
      "s3:GetBucketTagging",
      "s3:PutBucketVersioning",
      "s3:GetBucketVersioning",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketNotification",
      "s3:GetBucketNotification",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:TagResource",
      "sns:UntagResource",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:GetSubscriptionAttributes",
      "sns:SetSubscriptionAttributes",
      "sns:ListTagsForResource"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:CreateQueue",
      "sqs:DeleteQueue",
      "sqs:GetQueueAttributes",
      "sqs:SetQueueAttributes",
      "sqs:TagQueue",
      "sqs:UntagQueue"
    ]
    resources = ["*"]
  }
}

module "terraform_role" {
  source                    = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/iam-role?ref=main"
  role_name                 = "infra-role"
  trust_relationship_policy = data.aws_iam_policy_document.infra_role_trust_relationship_policy.json
  inline_policy             = data.aws_iam_policy_document.infra_role_inline_policy_document.json
  inline_policy_description = "Policy for Terraform role to manage AWS infrastructure"
  environment               = var.environment
  project                   = var.project_name
}

module "sns_email_subscription" {
  source         = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/sns-email-subscription?ref=main"
  sns_topic_name = "lambda-failure-notification-topic"
  user_email     = var.email
  environment    = var.environment
  project        = var.project_name
}