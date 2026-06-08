resource "aws_efs_file_system" "storage" {
  creation_token = "${var.project_name}-storage"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-storage"
  }
}

resource "aws_efs_mount_target" "storage" {
  count = length(aws_subnet.public)

  file_system_id  = aws_efs_file_system.storage.id
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.efs.id]
}
