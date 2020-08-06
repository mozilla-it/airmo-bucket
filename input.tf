variable "region" {
  default = "us-west-2"
}

variable "bucket_name" {
  default = "airmo"
}

variable "bucket_acl" {
  default = "private"
}

variable "remote_airmo_bucket" {
  default = "air-mozilla-uploads-prod"
}

variable "bucket_users" {
  type = list(string)
}

variable "cors_allowed_origins" {
  type = list(string)
}

variable "cors_max_age_seconds" {
  default = "3000"
}

variable "vendor_users" {
  type = list(string)
}

variable "magic_folder" {
  default = "encoding-com"
}

