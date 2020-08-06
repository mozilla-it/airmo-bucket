terraform {
  backend "s3" {
    bucket = "nubis-apps-state-00c43ad1acae59d84af2fa4390"
    key    = "terraform/us-west-2/core/stage/airmo-bucket"
    region = "eu-west-1"
  }
}

