output "alb_dns_name" {
  description = "DNS public name for the Load Balancer."
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint."
  value       = aws_db_instance.RDS.endpoint
}

output "efs_id" {
  description = "EFS file system ID."
  value       = aws_efs_file_system.main.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group for application servers."
  value       = aws_autoscaling_group.main_asg.name
}

output "launch_template_id" {
  description = "ID of the Launch Template used by the Auto Scaling Group."
  value       = aws_launch_template.app_lt.id
}

output "security_group_id" {
  description = "ID of the Security Group associated with the EC2 instances."
  value       = aws_security_group.ec2_sg.id
}

output "vpc_id" {
  description = "ID of the VPC where the resources are deployed."
  value       = aws_vpc.main.id
}






