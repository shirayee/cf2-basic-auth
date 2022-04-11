locals {
  encoded_credential = base64encode("${var.username}:${var.password}")
}

resource "aws_cloudfront_function" "default" {
  name    = var.function_name
  runtime = "cloudfront-js-1.0"
  publish = var.publish
  code    = templatefile("${path.module}/src/handler.js.tftpl", { encoded_credential = local.encoded_credential })
}
