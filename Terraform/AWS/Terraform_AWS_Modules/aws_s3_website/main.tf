resource "aws_s3_bucket_website_configuration" "this" {
  bucket = var.aws_s3_bucket

  index_document {
    suffix = var.aws_s3_index_document
  }

  error_document {
    key = var.aws_s3_error_document
  }

  dynamic "routing_rule" {
    for_each = var.aws_s3_redirect_routing_rules
    content {
      condition {
        key_prefix_equals = routing_rule.value.condition.key_prefix_equals
      }
      redirect {
        host_name = routing_rule.value.redirect.host_name
        protocol  = routing_rule.value.redirect.protocol
      }
    }
  }
}
