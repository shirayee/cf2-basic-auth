provider "aws" {
  region = "ap-northeast-1"
}

module "basic_auth" {
  source = "../../"

  username      = aws_ssm_parameter.username.value
  password      = aws_ssm_parameter.password.value
  function_name = var.function_name
}

resource "aws_ssm_parameter" "username" {
  name  = var.username_parameter_path
  type  = "String"
  value = "dummy"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "password" {
  name  = var.password_parameter_path
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_s3_bucket" "default" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.default.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "default" {
  bucket = aws_s3_bucket.default.bucket

  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.default.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.allow_public_read.json
}

resource "aws_s3_object" "index_page" {
  bucket       = aws_s3_bucket.default.id
  key          = "index.html"
  source       = "${path.module}/src/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/src/index.html")
}

resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name = aws_s3_bucket.default.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.default.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.default.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    function_association {
      event_type   = "viewer-request"
      function_arn = module.basic_auth.function_arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "default" {}
