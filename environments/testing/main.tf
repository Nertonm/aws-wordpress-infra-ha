
variable "db_password" {}
variable "key_pair_name" {}
variable "admin_ip" {}

module "wordpress_app" {
  source         = "../../modules/aws-wordpress-ha"
  db_password    = var.db_password
  key_pair_name  = var.key_pair_name
  environment    = "testing"
  admin_ip       = var.admin_ip
}

#data "http" "my_ip" {
  #$url = "http://ipv4.icanhazip.com"
#}