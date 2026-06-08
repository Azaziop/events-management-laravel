variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet (préfixe des ressources)"
  type        = string
  default     = "event-management"
}

variable "environment" {
  description = "Environnement (production, staging, etc.)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ecs_desired_count" {
  description = "Nombre de tâches ECS Fargate"
  type        = number
  default     = 1
}

variable "ecs_task_cpu" {
  description = "CPU Fargate (256, 512, 1024, ...)"
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Mémoire Fargate en Mo (512, 1024, 2048, ...)"
  type        = string
  default     = "1024"
}

variable "db_instance_class" {
  description = "Classe d'instance RDS PostgreSQL"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Nom de la base PostgreSQL"
  type        = string
  default     = "events_db"
}

variable "db_username" {
  description = "Utilisateur administrateur RDS"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Mot de passe RDS (sensible)"
  type        = string
  sensitive   = true
}

variable "app_key" {
  description = "Clé Laravel APP_KEY (base64:...)"
  type        = string
  sensitive   = true
}

variable "docker_image" {
  description = "Image Docker Hub de l'application"
  type        = string
  default     = "azaziop/event-management1"
}

variable "docker_image_tag" {
  description = "Tag de l'image Docker"
  type        = string
  default     = "latest"
}

variable "app_url" {
  description = "URL publique (laisser http://localhost pour utiliser le DNS de l'ALB)"
  type        = string
  default     = "http://localhost"
}
