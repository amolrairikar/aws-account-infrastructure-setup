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

variable "terraform_user_arn" {
  description = "The ARN for the Terraform user who will assume the infra role"
  type        = string
}