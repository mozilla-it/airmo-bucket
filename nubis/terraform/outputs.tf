output "bucket_name" {
  value = "${aws_s3_bucket.airmo-bucket.id}"
}

output "airmo_iam_users" {
  value = [ "${aws_iam_user.bucket-users.*.name}" ]
}

output "airmo_iam_access_key" {
  value = [ "${aws_iam_access_key.bucket-user-keys.*.id}" ]
}

output "airmo_iam_secret_key" {
  value = [ "${aws_iam_access_key.bucket-user-keys.*.secret}" ]
}
