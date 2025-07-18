terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  assume_role {
    role_arn     = var.infra_role_arn
    session_name = "terraform-session"
  }
}

# Data block that returns AWS account number
data "aws_caller_identity" "current" {}

# IAM policies + role definition for infra role used by Terraform
data "aws_iam_policy_document" "infra_role_trust_relationship_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:amolrairikar/aws-account-infrastructure-setup:ref:refs/heads/main",
        "repo:amolrairikar/aws-account-infrastructure-setup:ref:refs/heads/feature/*",
        "repo:amolrairikar/spotify-listening-history-app:ref:refs/heads/main",
        "repo:amolrairikar/spotify-listening-history-app:ref:refs/heads/feature/*",
        "repo:amolrairikar/cta-train-tracker-analytics:ref:refs/heads/main",
        "repo:amolrairikar/cta-train-tracker-analytics:ref:refs/heads/feature/*"
      ]
    }
  }
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/infra-role/GitHubActions"]
    }
  }
}

data "aws_iam_policy_document" "infra_role_inline_policy_document" {
  statement {
    effect    = "Allow"
    actions   = [
      "scheduler:*Schedule",
      "scheduler:ListSchedules"
    ]
    resources = [
      "arn:aws:scheduler:us-east-2:${data.aws_caller_identity.current.account_id}:schedule/default/spotify-listening-history-lambda-trigger",
      "arn:aws:scheduler:us-east-2:${data.aws_caller_identity.current.account_id}:schedule/default/cta-write-train-lines-lambda-trigger",
      "arn:aws:scheduler:us-east-2:${data.aws_caller_identity.current.account_id}:schedule/default/cta-bucket-raw-data-lambda-trigger"
    ]
  }
  statement {
  effect    = "Allow"
  actions   = [
    "iam:*Role",
    "iam:*RolePolicy",
    "iam:*RolePolicies",
    "iam:*Policy",
    "iam:*PolicyVersion",
    "iam:*OpenIDConnectProvider",
    "iam:PassRole",
    "iam:ListPolicyVersions",
    "iam:ListOpenIDConnectProviders",
    "iam:ListOpenIDConnectProviderTags",
    "iam:ListInstanceProfilesForRole"
  ]
  resources = ["*"]
}
  statement {
    effect    = "Allow"
    actions   = [
      "lambda:*Function",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:*Resource",
      "lambda:PutFunctionEventInvokeConfig",
      "lambda:DeleteFunctionEventInvokeConfig",
      "lambda:GetFunctionEventInvokeConfig",
      "lambda:*Permission",
      "lambda:GetPolicy",
      "lambda:ListVersionsByFunction",
      "lambda:GetFunctionCodeSigningConfig",
    ]
    resources = [
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:function:spotify-etl",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:function:spotify-listening-history",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:function:cta-get-train-status",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:function:cta-write-train-lines",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:function:cta-bucket-raw-data"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "lambda:*EventSourceMapping",
      "lambda:ListEventSourceMappings",
      "lambda:ListTags"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "lambda:*LayerVersion",
      "lambda:*LayerVersionPermission",
      "lambda:ListLayerVersions",
      "lambda:GetLayerVersionPolicy"
    ]
    resources = [
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:layer:retry_api_exceptions",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:layer:retry_api_exceptions:*",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:layer:pyarrow_layer",
      "arn:aws:lambda:us-east-2:${data.aws_caller_identity.current.account_id}:layer:pyarrow_layer:*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:ListLayers"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "s3:*Bucket",
      "s3:*BucketTagging",
      "s3:*ObjectTagging",
      "s3:*BucketVersioning",
      "s3:*BucketPublicAccessBlock",
      "s3:*BucketNotification",
      "s3:*Object",
      "s3:GetObjectVersion",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:*BucketPolicy",
      "s3:*BucketAcl",
      "s3:PutBucketAcl",
      "s3:*BucketOwnershipControls",
      "s3:GetBucketCORS",
      "s3:GetBucketWebsite",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketLogging",
      "s3:*LifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketObjectLockConfiguration"
    ]
    resources = [
      "arn:aws:s3:::aws-cloudtrail-logs-${data.aws_caller_identity.current.account_id}-659b67ac",
      "arn:aws:s3:::aws-cloudtrail-logs-${data.aws_caller_identity.current.account_id}-659b67ac/*",
      "arn:aws:s3:::cta-train-analytics-app-data-lake-${data.aws_caller_identity.current.account_id}-prod",
      "arn:aws:s3:::cta-train-analytics-app-data-lake-${data.aws_caller_identity.current.account_id}-prod/*",
      "arn:aws:s3:::lambda-source-code-${data.aws_caller_identity.current.account_id}-bucket",
      "arn:aws:s3:::lambda-source-code-${data.aws_caller_identity.current.account_id}-bucket/*",
      "arn:aws:s3:::spotify-listening-history-app-data-lake-${data.aws_caller_identity.current.account_id}-prod",
      "arn:aws:s3:::spotify-listening-history-app-data-lake-${data.aws_caller_identity.current.account_id}-prod/*",
      "arn:aws:s3:::terraform-state-bucket-${data.aws_caller_identity.current.account_id}-prod",
      "arn:aws:s3:::terraform-state-bucket-${data.aws_caller_identity.current.account_id}-prod/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sns:*Topic",
      "sns:*TopicAttributes",
      "sns:*Resource",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:*SubscriptionAttributes",
      "sns:ListTagsForResource"
    ]
    resources = [
      "arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:lambda-failure-notification-topic",
      "arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:lambda-failure-notification-topic:0e548f80-3d8a-4efb-9e65-8e3840395091"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:*Queue",
      "sqs:*QueueAttributes",
      "sqs:ListQueueTags"
    ]
    resources = [
      "arn:aws:sqs:us-east-2:${data.aws_caller_identity.current.account_id}:cta-trigger-get-train-status"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "cloudtrail:*Trail",
      "cloudtrail:*Logging",
      "cloudtrail:*Tags",
      "cloudtrail:PutEventSelectors",
      "cloudtrail:GetTrailStatus"
    ]
    resources = [
      "arn:aws:cloudtrail:us-east-2:${data.aws_caller_identity.current.account_id}:trail/management-events-trail"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["cloudtrail:DescribeTrails"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "logs:*LogGroup",
      "logs:*Resource",
      "logs:*RetentionPolicy"
    ]
    resources = [
      "arn:aws:logs:us-east-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*",
      "arn:aws:logs:us-east-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/*",
      "arn:aws:logs:us-east-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/firehose/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "firehose:*DeliveryStream",
      "firehose:UpdateDestination"
    ]
    resources = [
      "arn:aws:firehose:us-east-2:${data.aws_caller_identity.current.account_id}:deliverystream/cta-train-analytics-stream"
    ]
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

# Create a list variable of Lambda ARNs for any Lambda that should be triggered by EventBridge
locals {
  lambda_arns = [
    for name in var.lambda_function_names :
    "arn:aws:lambda:${var.aws_region_name}:${data.aws_caller_identity.current.account_id}:function:${name}"
  ]
}

# IAM policies + role definition for role used by EventBridge
data "aws_iam_policy_document" "eventbridge_trust_relationship_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_role_inline_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = local.lambda_arns
  }
}

module "eventbridge_role" {
  source                    = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/iam-role?ref=main"
  role_name                 = "eventbridge-role"
  trust_relationship_policy = data.aws_iam_policy_document.eventbridge_trust_relationship_policy.json
  inline_policy             = data.aws_iam_policy_document.eventbridge_role_inline_policy_document.json
  inline_policy_description = "Policy for EventBridge Scheduler to invoke Lambda functions"
  environment               = var.environment
  project                   = var.project_name
}

# OIDC provider for GitHub to allow GitHub Actions to authenticate without needing IAM access keys
resource "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# SNS subscription for all Lambda functions to send error notifications to
module "sns_email_subscription" {
  source         = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/sns-email-subscription?ref=main"
  sns_topic_name = "lambda-failure-notification-topic"
  user_email     = var.email
  environment    = var.environment
  project        = var.project_name
}

# S3 bucket + bucket policy for Cloudtrail bucket
module "cloudtrail_bucket" {
  source            = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/s3-bucket-private?ref=main"
  bucket_name       = "aws-cloudtrail-logs-${data.aws_caller_identity.current.account_id}-659b67ac"
  account_number    = data.aws_caller_identity.current.account_id
  environment       = var.environment
  project           = var.project_name
  versioning_status = "Disabled"
  enable_acl        = true
  bucket_acl        = "private"
  object_ownership  = "BucketOwnerPreferred"
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = module.cloudtrail_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:GetBucketAcl"
        Resource  = module.cloudtrail_bucket.bucket_arn
        Condition ={
          StringEquals = {
            "AWS:SourceARN" = aws_cloudtrail.management_event_trail.arn
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource  = "${module.cloudtrail_bucket.bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceARN" = aws_cloudtrail.management_event_trail.arn
          }
        }
      }
    ]
  })
}

# Management event trail for Cloudtrail
resource "aws_cloudtrail" "management_event_trail" {
  name                          = "management-events-trail"
  s3_bucket_name                = module.cloudtrail_bucket.bucket_id
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# S3 bucket + lifecycle policy for bucket holding all Lambda/Lambda layer source code
module "code_bucket" {
  source            = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/s3-bucket-private?ref=main"
  bucket_name       = "lambda-source-code-${data.aws_caller_identity.current.account_id}-bucket"
  account_number    = data.aws_caller_identity.current.account_id
  environment       = var.environment
  project           = var.project_name
  versioning_status = "Enabled"
  enable_acl        = false
  object_ownership  = "BucketOwnerEnforced"
}

resource "aws_s3_bucket_lifecycle_configuration" "code_bucket_lifecycle_config" {
  bucket = module.code_bucket.bucket_id

  rule {
    id      = "Expire old code artifacts"
    status  = "Enabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ZIP file corresponding to Lambda layer source code for retry_api_exceptions layer
data aws_s3_object "retry_api_exceptions_zip" {
  bucket = module.code_bucket.bucket_id
  key    = "retry_api_exceptions.zip"
}

# Deployment of Lambda layer for retry_api_exceptions layer
module "retry_api_call_layer" {
  source              = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/lambda-layer?ref=main"
  layer_name          = "retry_api_exceptions"
  layer_description   = "Layer for retrying API calls in Lambda functions"
  layer_architectures = ["x86_64"]
  layer_runtimes      = ["python3.12"]
  s3_bucket           = module.code_bucket.bucket_id
  s3_key              = "retry_api_exceptions.zip"
  s3_object_version   = data.aws_s3_object.retry_api_exceptions_zip.version_id
}

# ZIP file corresponding to Lambda layer source code for pyarrow layer
data aws_s3_object "pyarrow_zip" {
  bucket = module.code_bucket.bucket_id
  key    = "pyarrow.zip"
}

# Deployment of Lambda layer for pyarrow layer
module "pyarrow_layer" {
  source              = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/lambda-layer?ref=main"
  layer_name          = "pyarrow_layer"
  layer_description   = "Layer for pyarrow"
  layer_architectures = ["x86_64"]
  layer_runtimes      = ["python3.12"]
  s3_bucket           = module.code_bucket.bucket_id
  s3_key              = "pyarrow.zip"
  s3_object_version   = data.aws_s3_object.pyarrow_zip.version_id
}

# IAM policies + role definition for role used by Kinesis Firehose
data "aws_iam_policy_document" "firehose_trust_relationship_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose_role_inline_policy_document" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::cta-train-analytics-app-data-lake-${data.aws_caller_identity.current.account_id}-prod/raw/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::cta-train-analytics-app-data-lake-${data.aws_caller_identity.current.account_id}-prod",
    ]
  }
  statement {
    effect    = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:us-east-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/firehose/*"
    ]
  }
}

module "firehose_role" {
  source                    = "git::https://github.com/amolrairikar/aws-account-infrastructure.git//modules/iam-role?ref=main"
  role_name                 = "firehose-role"
  trust_relationship_policy = data.aws_iam_policy_document.firehose_trust_relationship_policy.json
  inline_policy             = data.aws_iam_policy_document.firehose_role_inline_policy_document.json
  inline_policy_description = "Policy for Firehose role to create delivery streams"
  environment               = var.environment
  project                   = var.project_name
}
