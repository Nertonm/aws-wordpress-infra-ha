
variable "db_password" {}
variable "key_pair_name" {}
variable "admin_ip" {}
variable "notification_email" {}

module "wordpress_app" {
  source         = "../../modules/aws-wordpress-ha"
  db_password    = var.db_password
  key_pair_name  = var.key_pair_name
  environment    = "testing"
  admin_ip       = var.admin_ip
  notification_email = var.notification_email
}

output "database_password" {
  value       = var.db_password
  description = "Database administrator password."
  sensitive   = true
}


output "alb_dns_name" {
  description = "DNS public name for the Load Balancer."
  value       = module.wordpress_app.alb_dns_name
}


output "rds_endpoint" {
  description = "RDS connection endpoint."
  value       = module.wordpress_app.rds_endpoint
}


output "efs_id" {
  description = "EFS file system ID."
  value       = module.wordpress_app.efs_id
}


output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group for application servers."
  value       = module.wordpress_app.autoscaling_group_name
}


output "launch_template_id" {
  description = "ID of the Launch Template used by the Auto Scaling Group."
  value       = module.wordpress_app.launch_template_id
}


output "security_group_id" {
  description = "ID of the Security Group associated with the EC2 instances."
  value       = module.wordpress_app.security_group_id
}


output "vpc_id" {
  description = "ID of the VPC where the resources are deployed."
  value       = module.wordpress_app.vpc_id
}


