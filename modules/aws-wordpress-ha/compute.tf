
resource "aws_launch_template" "app_lt" {
    name_prefix = "${var.project_name}-app-lt"
    description = "Launch Template for WordPress Application Servers"
    image_id    = var.ec2_ami_id
    instance_type = var.ec2_instance_type
    key_name      = var.key_pair_name

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2_instance_profile.name
    }
    # vpc_security_group_ids = [aws_security_group.ec2_sg.id]

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

    network_interfaces {
      associate_public_ip_address = var.ec2_associate_public_ip_address
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

resource "aws_autoscaling_group" "main_asg" {
  name_prefix = "${var.project_name}-app-asg"

  desired_capacity = var.ec2_asg_desired_capacity
  max_size         = var.ec2_asg_max_size
  min_size         = var.ec2_asg_min_size

  # Private Subnets for ASG
  vpc_zone_identifier = aws_subnet.private_subnets[*].id
    
  # Target Group for ASG
  target_group_arns = [aws_alb_target_group.main.arn]

  health_check_type = "ELB"
  health_check_grace_period = 300

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
