provider "aws" {
  version = "~> 2"
  region  = var.region
}

locals {
  bucket_name = "${var.bucket_name}-${random_id.rand-var.hex}"
}

resource "random_id" "rand-var" {
  keepers = {
    bucket_name = var.bucket_name
  }

  byte_length = 8
}

# Policy given by Andy
data "aws_iam_policy_document" "airmo-bucket" {

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::831879419742:user/content-conversions-executor"
      ]
    }
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::831879419742:user/content-conversions-executor"
      ]
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::831879419742:role/beta-migration-awsBatchSpotInstanceRole"
      ]
    }
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::831879419742:role/beta-migration-awsBatchSpotInstanceRole"
      ]
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }

}

resource "aws_s3_bucket" "airmo-bucket" {
  bucket = "${var.bucket_name}-${random_id.rand-var.hex}"
  acl    = var.bucket_acl
  policy = data.aws_iam_policy_document.airmo-bucket.json

  # only has support for 1 rule atm
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = var.cors_allowed_origins
    max_age_seconds = var.cors_max_age_seconds
  }

  tags = {
    Name      = "${var.bucket_name}-${random_id.rand-var.hex}"
    Region    = var.region
    Terraform = "true"
  }
}

resource "aws_iam_user" "bucket-users" {
  count = length(var.bucket_users)
  name  = element(var.bucket_users, count.index)

  tags = {
    Name      = element(var.bucket_users, count.index)
    Terraform = "true"
  }
}

resource "aws_iam_access_key" "bucket-user-keys" {
  count = length(var.bucket_users)
  user  = element(var.bucket_users, count.index)
}

resource "aws_iam_group" "airmo-bucket-group" {
  name = "AirmoBucketAccess"
  path = "/nubis/"
}

data "aws_iam_policy_document" "bucket-policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBuckets",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${aws_s3_bucket.airmo-bucket.arn}",
      "${aws_s3_bucket.airmo-bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.remote_airmo_bucket}",
      "arn:aws:s3:::${var.remote_airmo_bucket}/*"
    ]
  }
}

resource "aws_iam_group_policy" "bucket-policy" {
  name   = "airmo-s3-bucket-access"
  group  = aws_iam_group.airmo-bucket-group.id
  policy = data.aws_iam_policy_document.bucket-policy.json
}

resource "aws_iam_group_membership" "bucket-group-members" {
  name  = "bucket-group-members"
  users = aws_iam_user.bucket-users.*.name
  group = aws_iam_group.airmo-bucket-group.name
}

# Messy code here, because vendor access.
# Also..because reasons
resource "aws_iam_user" "vendor-users" {
  count = length(var.vendor_users)
  name  = element(var.vendor_users, count.index)
}

resource "aws_iam_access_key" "vendor-user-keys" {
  count = length(var.vendor_users)
  user  = element(var.vendor_users, count.index)
}

resource "aws_iam_group" "vendor-group" {
  name = "AirmoVendorAccess"
  path = "/nubis/"
}

resource "aws_iam_group_membership" "vendor-group-members" {
  name  = "vendor-group-members"
  users = aws_iam_user.vendor-users.*.name
  group = aws_iam_group.vendor-group.name
}

data "aws_iam_policy_document" "vendor-access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListMyBuckets",
      "s3:ListAllMyBuckets"
    ]

    resources = [
      "arn:aws:s3:::*"
    ]
  }

  statement {
    sid    = "AllowS3UserToListSubFolder"
    effect = "Allow"
    actions = [
      "s3:*"
    ]

    resources = [
      "${aws_s3_bucket.airmo-bucket.arn}/${var.magic_folder}",
      "${aws_s3_bucket.airmo-bucket.arn}/${var.magic_folder}/*"
    ]
  }
}

resource "aws_iam_group_policy" "vendor-access" {
  name   = "airmo-s3-vendor-access"
  group  = aws_iam_group.vendor-group.id
  policy = data.aws_iam_policy_document.vendor-access.json

}

