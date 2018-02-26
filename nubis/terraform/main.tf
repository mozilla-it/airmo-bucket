provider "aws" {
  version = "~> 0.1"
  region  = "${var.region}"
}

resource "random_id" "rand-var" {

  keepers = {
    bucket_name = "${var.bucket_name}"
  }

  byte_length = 8
}

resource "aws_s3_bucket" "airmo-bucket" {

  bucket  = "${var.bucket_name}-${random_id.rand-var.hex}"
  acl     = "${var.bucket_acl}"

  # only has support for 1 rule atm
  cors_rule {
    allowed_headers = [ "*" ]
    allowed_methods = [ "GET", "PUT", "POST" ]
    allowed_origins = [ "${var.cors_allowed_origins}" ]
    max_age_seconds = "${var.cors_max_age_seconds}"
  }

  tags {
    Name              = "${var.bucket_name}-${random_id.rand-var.hex}"
    ServiceName       = "${var.service_name}"
    TechnicalContact  = "${var.technical_contact}"
  }

}

resource "aws_iam_user" "bucket-users" {
  count = "${length(var.bucket_users)}"
  name  = "${element(var.bucket_users, count.index)}"
}

resource "aws_iam_access_key" "bucket-user-keys" {
  count = "${length(var.bucket_users)}"
  user  = "${element(var.bucket_users, count.index)}"
}

resource "aws_iam_group" "airmo-bucket-group" {
  name  = "AirmoBucketAccess"
  path  = "/nubis/"
}

resource "aws_iam_group_policy" "bucket-policy" {
  name  = "airmo-s3-bucket-access"
  group = "${aws_iam_group.airmo-bucket-group.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBuckets",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.airmo-bucket.arn}",
        "${aws_s3_bucket.airmo-bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.remote_airmo_bucket}",
        "arn:aws:s3:::${var.remote_airmo_bucket}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_group_membership" "bucket-group-members" {
  name  = "bucket-group-members"
  users = [
    "${aws_iam_user.bucket-users.*.name}"
  ]

  group = "${aws_iam_group.airmo-bucket-group.name}"
}

# Messy code here, because vendor access.
# Also..because reasons
resource "aws_iam_user" "vendor-users" {
  count = "${length(var.vendor_users)}"
  name  = "${element(var.vendor_users, count.index)}"
}

resource "aws_iam_access_key" "vendor-user-keys" {
  count = "${length(var.vendor_users)}"
  user  = "${element(var.vendor_users, count.index)}"
}


resource "aws_iam_group" "vendor-group" {
  name  = "AirmoVendorAccess"
  path  = "/nubis/"
}

resource "aws_iam_group_membership" "vendor-group-members" {
  name  = "vendor-group-members"
  users = [
    "${aws_iam_user.vendor-users.*.name}"
  ]

  group = "${aws_iam_group.vendor-group.name}"
}

resource "aws_iam_group_policy" "vendor-access" {
  name    = "airmo-s3-vendor-access"
  group   = "${aws_iam_group.vendor-group.id}"

  policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListMyBuckets",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Sid": "AllowS3UserToListRootFolder",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.airmo-bucket.arn}"
      ]
    },
    {
      "Sid": "AllowS3UserToListSubFolder",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.airmo-bucket.arn}/${var.magic_folder}/*"
      ]
    }
  ]
}
EOF
}
