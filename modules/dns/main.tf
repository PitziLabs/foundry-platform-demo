# modules/dns/main.tf

# --- Route 53 Hosted Zone ---
# This makes Route 53 the authoritative DNS for the domain.
# After creation, you must update nameservers at your registrar (Squarespace)
# to point to the NS records Route 53 assigns. This is a one-time manual step.
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "${var.project}-${var.environment} hosted zone"

  tags = {
    Name = "${var.project}-${var.environment}-zone"
  }
}

# --- ACM TLS Certificate ---
# Requests a free public certificate from AWS Certificate Manager.
# Uses DNS validation: ACM gives us a CNAME record to create in Route 53,
# and once it sees that record, it issues the cert. Fully automated below.
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  tags = {
    Name = "${var.project}-${var.environment}-cert"
  }

  # Lifecycle rule: if we ever need to replace the cert (e.g., adding SANs),
  # create the new one before destroying the old one so the ALB never goes
  # without a valid cert. This is a production best practice.
  lifecycle {
    create_before_destroy = true
  }
}

# --- DNS Validation Records ---
# ACM tells us exactly which CNAME records to create to prove domain ownership.
# This dynamically creates one validation record per domain on the certificate.
# The for_each with toset() deduplicates records — important because the bare
# domain and wildcard often share the same validation record.
resource "aws_route53_record" "acm_validation" {
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
  zone_id         = aws_route53_zone.main.zone_id
}

# --- Certificate Validation Waiter ---
# This resource doesn't create anything in AWS. It tells Terraform to wait
# until ACM has verified the DNS records and actually issued the certificate.
# Without this, Terraform would move on and the ALB listener would fail
# because it's referencing a cert that hasn't been issued yet.
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
# --- ALB Alias Record ---
# Points the bare domain at the ALB. An alias record is AWS-specific:
# it's like a CNAME but works at the zone apex (bare domain) and
# doesn't incur Route 53 query charges. Only created when ALB values
# are provided, since the ALB doesn't exist yet during the initial
# dns module apply.
resource "aws_route53_record" "alb_alias" {
  count = var.create_alb_alias ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}