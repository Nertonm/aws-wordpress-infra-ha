module "wordpress_app" {
  source       = "../../modules/aws-wordpress-ha"
  db_password = ""
  key_pair_name = ""
  environment = "testing"
  admin_ip = ""
}

#data "http" "my_ip" {
  #$url = "http://ipv4.icanhazip.com"
#}