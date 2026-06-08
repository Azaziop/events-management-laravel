terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Décommentez pour un backend distant (recommandé en équipe)
  # backend "s3" {
  #   bucket         = "votre-bucket-terraform-state"
  #   key            = "event-management/terraform.tfstate"
  #   region         = "eu-west-3"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}
