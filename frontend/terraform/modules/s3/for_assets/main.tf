variable "stage" { type = string }

module "values" {
  source = "../../../values"
}

resource "aws_s3_bucket" "static_files_bucket" {
  bucket = "${module.values.appname}-${var.stage}-static-files"
}

resource "aws_s3_bucket_versioning" "static_files_versioning" {
  bucket = aws_s3_bucket.static_files_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "static_files_policy" {
  bucket = aws_s3_bucket.static_files_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_files_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for Next.js static files bucket"
}
