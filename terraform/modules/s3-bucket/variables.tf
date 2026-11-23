variable "name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key used for default SSE-KMS encryption."
  type        = string
}
