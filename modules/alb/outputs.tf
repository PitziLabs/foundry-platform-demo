# modules/alb/outputs.tf

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB (used for Route 53 alias record)"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (needed for Route 53 alias record)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group (ECS service registers tasks here)"
  value       = aws_lb_target_group.app.arn
}