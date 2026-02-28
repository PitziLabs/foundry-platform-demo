# modules/ecr/main.tf

resource "aws_ecr_repository" "this" {
  name                 = "${var.project}-${var.environment}-app"
  image_tag_mutability = var.image_tag_mutability

  # Scan every image on push for known CVEs — free and automatic
  image_scanning_configuration {
    scan_on_push = true
  }

  # Force delete even if images exist — appropriate for a lab repo
  # In production you'd want this false to prevent accidental deletion
  force_delete = true

  tags = var.tags
}

# Lifecycle policy keeps storage costs from growing unboundedly.
# This keeps the most recent N images and purges older untagged ones.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last ${var.max_image_count} untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.max_image_count} tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPatternList = ["*"]
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}