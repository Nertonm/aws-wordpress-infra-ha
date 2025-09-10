# Criação da Role IAM para EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  ## Política que permite que o serviço EC2 assuma esta role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

# Cria a política gerenciada da AWS para permitir que o EC2 use o Systems Manager (SSM)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Anexa a política gerenciada da AWS para permitir que o EC2 seja acessado por SSM
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile-${var.environment}"
  }
}
