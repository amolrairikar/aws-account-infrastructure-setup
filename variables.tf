variable "infra_role_arn" {
  description = "The ARN for the role assumed by the Terraform user"
  type        = string
}

variable "email" {
  description = "Developer email to send notifications to"
  type        = string
}

variable "environment" {
  description = "The deployment environment (QA or PROD)"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
}

variable "account_number" {
  description = "The AWS account number"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "lambda_function_names" {
  description = "The names of all Lambda functions in the account"
  type        = list(string)
  default     = [
    "spotify-etl-lambda",
    "spotify-listening-history-lambda",
    "cta-get-train-status-lambda"
  ]
}