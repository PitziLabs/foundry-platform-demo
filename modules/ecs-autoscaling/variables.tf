# modules/ecs-autoscaling/variables.tf

variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster containing the service to scale"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service to scale"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks (floor — auto-scaler will never go below this)"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks (ceiling — bounds cost even under heavy load)"
  type        = number
  default     = 6
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage (auto-scaler tries to keep CPU near this value)"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage (optional second scaling dimension)"
  type        = number
  default     = 70
}

variable "scale_in_cooldown" {
  description = "Seconds to wait after a scale-in before allowing another scale-in (prevents flapping)"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Seconds to wait after a scale-out before allowing another scale-out"
  type        = number
  default     = 60
}