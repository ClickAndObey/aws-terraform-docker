resource "aws_s3_bucket" "bucket1" {
  bucket = var.bucket_name
  acl    = "private"
}
