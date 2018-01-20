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
  acl     = "private"

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
