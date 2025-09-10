# Criação do EFS
resource "aws_efs_file_system" "main" {
    ## Configuração do sistema de arquivos EFS
    encrypted = var.efs_encrypted
    performance_mode = var.efs_performance_mode
    throughput_mode  = var.efs_throughput_mode
    tags = {
        Name = "${var.project_name}-efs-${var.environment}"
    }
}

# EFS Mount Target
resource "aws_efs_mount_target" "main" {
    ## Configuração do ponto de montagem do EFS
    count = length(aws_subnet.private_subnets[*].id)
    file_system_id = aws_efs_file_system.main.id
 
    ## Cada ponto de montagem será criado em uma sub-rede privada
    subnet_id = aws_subnet.private_subnets[count.index].id
    security_groups = [aws_security_group.efs_sg.id]
}