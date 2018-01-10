variable "environment" {
  default = "stage"
}

variable "region" {
  default = "us-west-2"
}

variable "bucket_name" {
  default = "airmo"
}

variable "service_name" {
}

variable "technical_contact" {
  default = "infra-webops@mozilla.com"
}

variable "bucket_users" {
  type  = "list"
}
