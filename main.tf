

##
## LOCALS
##
locals {
  source_dir        = "${path.module}/source" // really "${path.cwd}/source"
  context           = jsondecode(var.exo_context)
  service           = local.context.service.name
  service_uid       = substr(local.context.service.id, -5, -1)
  service_name_safe = join("-", split(" ", lower(replace(local.context.service.name, "[^\\w\\d]|_", ""))))
  service_key       = "${local.service_name_safe}-${local.service_uid}"
}


##
## Hosted Zone
##

data "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 0 : 1
  name  = var.domain
}

resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.domain
}

locals {
  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.main[0].zone_id
}


##
## TLD CERT - example.com
##

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}

resource "aws_route53_record" "main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}

##
## SUB CERT - *.example.com
##

resource "aws_acm_certificate" "sub" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "sub" {
  certificate_arn         = aws_acm_certificate.sub.arn
  validation_record_fqdns = [for record in aws_route53_record.sub : record.fqdn]
}

resource "aws_route53_record" "sub" {
  for_each = {
    for dvo in aws_acm_certificate.sub.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}
