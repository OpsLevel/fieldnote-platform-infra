variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "cluster_name" {
  type    = string
  default = "fieldnote-prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
