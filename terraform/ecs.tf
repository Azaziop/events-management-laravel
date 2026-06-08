locals {
  app_url = var.app_url != "http://localhost" ? var.app_url : "http://${aws_lb.main.dns_name}"

  nginx_config_b64 = base64encode(file("${path.module}/../docker/nginx/ecs-default.conf"))

  backend_startup = <<-EOT
    set -e
    mkdir -p /shared/public
    cp -a /var/www/html/public/. /shared/public/
    mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data storage/logs bootstrap/cache
    chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
    chmod -R 777 storage bootstrap/cache
    su -s /bin/sh www-data -c 'php artisan config:clear && php artisan migrate --force'
    mkdir -p storage/app/public/events
    ln -sfn /var/www/html/storage/app/public /shared/public/storage
    touch /shared/public/.ready
    exec php-fpm
  EOT

  nginx_startup = <<-EOT
    echo '${local.nginx_config_b64}' | base64 -d > /etc/nginx/conf.d/default.conf
    for i in $(seq 1 60); do
      if [ -f /var/www/html/public/.ready ]; then
        break
      fi
      sleep 2
    done
    exec nginx -g 'daemon off;'
  EOT
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "public-assets"
  }

  volume {
    name = "storage-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.storage.id
      transit_encryption = "ENABLED"
      root_directory     = "/"

      authorization_config {
        iam = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.docker_image}:${var.docker_image_tag}"
      essential = true
      user      = "root"
      command   = ["sh", "-c", local.backend_startup]
      environment = [
        { name = "APP_ENV", value = "production" },
        { name = "APP_KEY", value = var.app_key },
        { name = "APP_URL", value = local.app_url },
        { name = "DB_CONNECTION", value = "pgsql" },
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_PORT", value = tostring(aws_db_instance.main.port) },
        { name = "DB_DATABASE", value = var.db_name },
        { name = "DB_USERNAME", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "SESSION_DRIVER", value = "database" },
        { name = "CACHE_STORE", value = "database" },
        { name = "QUEUE_CONNECTION", value = "sync" },
        { name = "LOG_CHANNEL", value = "stderr" },
      ]
      mountPoints = [
        {
          sourceVolume  = "public-assets"
          containerPath = "/shared/public"
          readOnly      = false
        },
        {
          sourceVolume  = "storage-data"
          containerPath = "/var/www/html/storage"
          readOnly      = false
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "test -f /shared/public/.ready || exit 1"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    },
    {
      name      = "nginx"
      image     = "nginx:alpine"
      essential = true
      command   = ["sh", "-c", local.nginx_startup]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
      ]
      mountPoints = [
        {
          sourceVolume  = "public-assets"
          containerPath = "/var/www/html/public"
          readOnly      = true
        },
        {
          sourceVolume  = "storage-data"
          containerPath = "/var/www/html/storage"
          readOnly      = true
        },
      ]
      dependsOn = [
        {
          containerName = "backend"
          condition     = "HEALTHY"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "nginx"
        }
      }
    },
  ])

  tags = {
    Name = "${var.project_name}-task"
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-service"
  }
}
