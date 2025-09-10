resource "aws_efs_file_system" "main" {
    encrypted = var.efs_encrypted
    performance_mode = var.efs_performance_mode
    throughput_mode  = var.efs_throughput_mode
    #lifecycle_policy {
    #    transition_to_ia = var.efs_transition_to_ia
    #}
    tags = {
        Name = "${var.project_name}-efs-${var.environment}"
    }
}

# EFS Mount Target
resource "aws_efs_mount_target" "main" {
    count = length(aws_subnet.private_subnets[*].id)
    file_system_id = aws_efs_file_system.main.id
    subnet_id = aws_subnet.private_subnets[count.index].id
    security_groups = [aws_security_group.efs_sg.id]
}