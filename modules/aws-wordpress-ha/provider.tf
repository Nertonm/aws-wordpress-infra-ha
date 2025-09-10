terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
        }
        http = {
        source  = "hashicorp/http"
        version = ">3.4.0" 
        }
    }
}
provider "aws" {
    region = "us-east-1"
    profile = "default"
    default_tags {
        tags = {
        }
    }
}