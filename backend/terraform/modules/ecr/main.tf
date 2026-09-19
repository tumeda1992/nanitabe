variable "stage" { type = string }

module "values" {
  source = "../../values"
}

resource "aws_ecr_repository" "repo" {
  name = "${module.values.appname}/rails-on-ecs/${var.stage}"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.repo.name

  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "最新の1つを残してイメージを削除する"
          rulePriority = 1
          selection = {
            countNumber = 1
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
}

output "repository_url" {
  value       = aws_ecr_repository.repo.repository_url
}

output "repository_name" {
  value = aws_ecr_repository.repo.name
}
