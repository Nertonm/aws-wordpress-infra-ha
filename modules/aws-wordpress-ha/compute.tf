# Criação do Template para as EC2
resource "aws_launch_template" "app_lt" {
    name_prefix = "${var.project_name}-app-lt"
    description = "Launch Template for WordPress Application Servers"
    
    ## Imagem da EC2, definido pelo variables
    image_id    = var.ec2_ami_id
    ## Tipo de Instacia, definido pelo variables
    instance_type = var.ec2_instance_type
    ## Nome da Chave, definido por var
    key_name      = var.key_pair_name

    ## IAM com SSM habilitado
    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_instance_profile.name
    }

    ## User Data da instancia com variaveis passadas pelo terraform
    user_data = base64encode(templatefile("${path.module}/user-data.sh", {
        compose_dir = var.user_data_compose_dir  
        efs_mount_point = var.efs_mount_point
        efs_dns_name = aws_efs_file_system.main.dns_name
        db_endpoint = aws_db_instance.RDS.endpoint
        db_name = var.db_name
        db_username = var.db_username
        db_password = var.db_password
        wordpress_version = var.wordpress_version
        compose_file    = "${var.user_data_compose_dir}/docker-compose.yml"
    }))

    ## Associação de Interfaces de Rede da EC2
    network_interfaces {
      ### Por padrão é falso mas se alguem quiser que seja verdadeiro
      associate_public_ip_address = var.ec2_associate_public_ip_address
      ### Security Group das EC2
      security_groups = [aws_security_group.ec2_sg.id]
    }

    tag_specifications {
        resource_type = "instance"
        tags = var.custom_tags
    }
    
    tag_specifications {
        resource_type = "volume"
        tags = var.custom_tags
    }

}

# Criação do Auto Scalling Group
resource "aws_autoscaling_group" "main_asg" {
  name_prefix = "${var.project_name}-app-asg"

  # Variaveis são defininidas por var
  desired_capacity = var.ec2_asg_desired_capacity
  max_size         = var.ec2_asg_max_size
  min_size         = var.ec2_asg_min_size

  # Private Subnets for ASG
  vpc_zone_identifier = aws_subnet.private_subnets[*].id
    
  # Target Group for ASG
  target_group_arns = [aws_alb_target_group.main.arn]

  health_check_type = "ELB"
  health_check_grace_period = var.asg_health_check_grace_period

  # Utiliza o launch_template criado anteriormente
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
}

# Configuração pra scalling up
resource "aws_autoscaling_policy" "cpu_target_policy" {
  name = "${var.project_name}-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.main_asg.name
  policy_type = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.asg_scale_up_target_value
  }
}

# Configuração CloudWatch Alarm para monitorar CPU 
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name = "${var.project_name}-high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = var.cloudwatch_evaluation_periods
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = var.cloudwatch_period
  statistic = "Average"
  threshold = var.cloudwatch_threshold 
  alarm_description = "Este alarme dispara se a utilização média da CPU exceder os limites predefinidos."

  # O alarme aponta para o Tópico SNS. O Tópico se encarrega de enviar para o e-mail.
  alarm_actions = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main_asg.name
  }
}

# Tópico SNS para centralizar os alertas
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-topic"
}

# Criação do Tópico SNS para notificações
resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email # O e-mail que receberá os alertas
}

