variable "infra_role_arn" {
  description = "The ARN for the role assumed by the Terraform user"
  type        = string
}

variable "account_number" {
  description = "The AWS account number"
  type        = string
}