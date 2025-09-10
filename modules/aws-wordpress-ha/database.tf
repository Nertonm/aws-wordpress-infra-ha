# Criação da RDS Instance
resource "aws_db_instance" "RDS" {
  ## Configuração da RDS Instance
  identifier = "${var.project_name}-rds"
  allocated_storage    = "${var.db_allocated_storage}"
  storage_type         = "${var.db_storage_type}"
  engine               = "${var.db_engine}"
  engine_version       = "${var.db_engine_version}"
  instance_class       = "${var.db_instance_class}"
  db_name              = "${var.db_name}"
  username             = "${var.db_username}"
  password             = "${var.db_password}"
  skip_final_snapshot  = "${var.db_skip_final_snapshot}"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible = "${var.db_publicly_accessible}"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  multi_az              = "${var.db_multi_az}"

  tags = {
    Name = "${var.project_name}-rds"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "${var.project_name}-db-subnet-group"
  
  ## Configuração do grupo de sub-redes
  subnet_ids = aws_subnet.private_subnets[*].id
  description = "Subnet group for RDS instance"
}