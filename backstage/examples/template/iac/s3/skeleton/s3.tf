locals {
  versioning_enabled = ${{ values.versioning }}
}

resource "aws_s3_bucket" "this" {
  bucket = "${{ values.name }}"
}

resource "aws_s3_bucket_versioning" "this" {
  count = local.versioning_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.bucket
  versioning_configuration {
    status = "Enabled"
  }
}
