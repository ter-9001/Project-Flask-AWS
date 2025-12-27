# Create a ECR repository

resource "aws_ecr_repository" "flask_repo" {
  name                 = "flask-app-aws"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  description = "URL do Repositório ECR"
  value       = aws_ecr_repository.flask_repo.repository_url
}
