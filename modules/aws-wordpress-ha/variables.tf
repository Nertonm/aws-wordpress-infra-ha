# AWS region
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy resources"
}

# Project name
variable "project_name" {
  type        = string
  default     = "wordpress-ha"
  description = "Project name for tagging resources" 
}

# VPC name
variable "vpc_name" {
  type        = string
  description = "Name of VPC"
  default = "main"
}

# NAT Gateway number
variable "nat_gateway_count" {
    description = "Number of NAT Gateways to create (one per public subnet), for testing use 1"
    type        = number
    default     = 1
    validation {
        condition     = var.nat_gateway_count <= length(var.az)
        error_message = "NAT Gateway count cannot exceed the number of availability zones"
    }
}

# Subnets availability zones
variable "az" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Availability zones"
}

# VPC CIDR
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
}

# Private subnets CIDR list
variable "private_subnets_cidr" {
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
  description = "Private subnets CIDR"
}

# Public subnets CIDR list
variable "public_subnets_cidr" {
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
  description = "Public subnets CIDR"
}

variable "admin_ip" {
  description = "Admin ip address to allow SSH access."
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "db_allocated_storage" {
  description = "Alocated storage in GB for the RDS instance."
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "Storage type for the RDS."
  type        = string
  default     = "gp3"
}

variable "db_engine" {
  description = "Database engine."
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version."
  type        = string
  default     = "8.0.42"
}

variable "db_instance_class" {
  description = "RDS instance class (machine size)."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name to be created."
  type        = string
  default     = "db_wordpress"
}

variable "db_username" {
  description = "Database administrator username."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database administrator password."
  type        = string
  sensitive   = true
  # No default for security reasons.
}

variable "db_skip_final_snapshot" {
    description = "If true, the RDS will be deleted without creating a final snapshot."
    type        = bool
    default     = true
}

variable "db_publicly_accessible" {
    description = "If true, the RDS will be publicly accessible."
    type        = bool
    default     = false
}

variable "db_multi_az" {
    description = "If true, the RDS will be deployed in multiple availability zones."
    type        = bool
    default     = false
}

variable "efs_performance_mode" {
    description = "EFS performance mode."
    type        = string
    default     = "generalPurpose"
  
}

variable "efs_throughput_mode" {
    description = "Throughput mode for the EFS."
    type        = string
    default     = "bursting"

}

variable "efs_transition_to_ia" {
    description = "Transition to infrequent access (IA) storage after how many days."
    type        = string
    default     = "AFTER_NEVER"
}

variable "efs_encrypted" {
    description = "If true, the EFS will be encrypted."
    type        = bool
    default     = true
}

variable "custom_tags" {
  description = "Mapa de tags personalizadas para aplicar aos recursos."
  type        = map(string)
  default = {
    Name       = "" 
    CostCenter = ""
    Project    = ""
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type for application servers."
  type        = string
  default     = "t2.micro" 
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-00ca32bbc84273381"  # Amazon Linux
}

variable "key_pair_name" {
  description = "Key pair name for SSH access to EC2 instances."
  type        = string
  default     = "teste2"
}

variable "ec2_associate_public_ip_address" {
  description = "If true, associates a public IP address with the EC2 instances."
  type        = bool
  default     = false
}

variable "alb_timeout" {
    description = "Timeout for the ALB health check."
    type        = number
    default     = 5
}

variable "alb_interval" {
    description = "Interval between ALB health checks."
    type        = number
    default     = 30
}

variable "alb_healthy_threshold" {
    description = "NNumber of successful attempts required to consider an instance healthy."
    type        = number
    default     = 3
}

variable "alb_unhealthy_threshold" {
    description = "NNumber of failed attempts required to consider an instance unhealthy."
    type        = number
    default     = 2
}

variable "ec2_asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "ec2_asg_min_size" {
  description = "Minimum size of the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "ec2_asg_max_size" {
  description = "Maximum size of the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "user_data_compose_dir" {
  description = "Directory where the docker-compose.yml file is located on the EC2 instance."
  type        = string
  default     = "/home/ec2-user/wordpress"
}

variable "efs_mount_point" {
  description = "Directory where the EFS will be mounted on the EC2 instance."
  type        = string
  default     = "/mnt/efs"
}

variable "wordpress_version" {
  description = "Wordpress version in docker"
  type = string
  default = "latest"
}