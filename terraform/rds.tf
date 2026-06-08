resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  apply_immediately      = true
  multi_az               = false

  skip_final_snapshot        = true
  deletion_protection        = false
  backup_retention_period    = 1 # Free Tier AWS : max 1 jour
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-rds"
  }
}
