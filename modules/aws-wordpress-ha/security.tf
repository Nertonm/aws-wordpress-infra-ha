# Security Group para o Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "${var.project_name}-lb-sg-${var.environment}"
  description = "Load Balancer access control"
  vpc_id      = aws_vpc.main.id

  # INBOUND: Permite tráfego HTTP da internet
  ingress {
    description = "Allow HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite que o LB envie tráfego para qualquer lugar (principalmente para as EC2s)
  egress { 
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lb-sg-${var.environment}"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg-${var.environment}"
  description = "EC2 access for control"
  vpc_id      = aws_vpc.main.id

  # INBOUND: Permite acesso SSH para manutenção
  ingress {
    description = "Allow SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip] 
  }

  ingress {
    description     = "Allow HTTP from Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }


  # OUTBOUND: Permite todo o tráfego para a internet (via NAT Gateway)
  # Isso é necessário para atualizações (yum/apt), e para conectar ao RDS e EFS.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg-${var.environment}"
  }
}

# Security Group para o RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "RDS access control"
  vpc_id      = aws_vpc.main.id


  ingress {
    description     = "Allow MySQL from EC2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # OUTBOUND: Não é estritamente necessário definir regras de saída (devido ao statefulness).

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}

# Security Group para o EFS
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg-${var.environment}"
  description = "EFS access control"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow NFS from EC2 instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  
  tags = {
    Name = "${var.project_name}-efs-sg-${var.environment}"
  }
}

resource "aws_security_group_rule" "lb_to_ec2" {
  type = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = aws_security_group.lb_sg.id
  source_security_group_id = aws_security_group.ec2_sg.id  
  description = "Allow HTTP from Load Balancer to EC2"
}
