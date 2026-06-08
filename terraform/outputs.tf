output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security group ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group tâches ECS"
  value       = aws_security_group.ecs_tasks.id
}

output "db_security_group_id" {
  description = "Security group base de données"
  value       = aws_security_group.db.id
}

output "rds_endpoint" {
  description = "Endpoint RDS PostgreSQL"
  value       = aws_db_instance.main.endpoint
}

output "alb_dns_name" {
  description = "DNS de l'Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "URL d'accès à l'application"
  value       = local.app_url
}

output "ecs_cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nom du service ECS"
  value       = aws_ecs_service.app.name
}

output "ecs_task_family" {
  description = "Famille de task definition ECS"
  value       = aws_ecs_task_definition.app.family
}

output "cloudwatch_log_group" {
  description = "Groupe de logs CloudWatch ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_dashboard_name" {
  description = "Nom du dashboard CloudWatch"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL console CloudWatch du dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards/dashboard/${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_alerts_topic_arn" {
  description = "ARN du topic SNS pour les alertes"
  value       = aws_sns_topic.alerts.arn
}
