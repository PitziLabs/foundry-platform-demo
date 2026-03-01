# modules/ecs-autoscaling/outputs.tf

output "cpu_policy_arn" {
  description = "ARN of the CPU scaling policy"
  value       = aws_appautoscaling_policy.cpu.arn
}

output "memory_policy_arn" {
  description = "ARN of the memory scaling policy"
  value       = aws_appautoscaling_policy.memory.arn
}