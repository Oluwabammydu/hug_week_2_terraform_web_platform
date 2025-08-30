terraform {
  required_version = ">= 1.12.0"

  # backend "s3" {
  #   bucket         = "hug-projects-terraform-state-bucket/project-2/"   
  #   key            = "dev/terraform.tfstate"       
  #   region         = "us-east-1"
  #   dynamodb_table = "state-locking"    
  #   encrypt        = true
  # }

  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source               = "../../modules/networking"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  tags                 = { Name = "tf-demo-dev" }
}

module "compute" {
  source          = "../../modules/compute"
  name            = "web-app"
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnets
  private_subnets = module.networking.private_subnets
  ami             = "ami-00ca32bbc84273381"
  instance_type   = "t3.micro"
  tags = { Name = "web-app" }
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = var.db_secret_id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

module "database" {
  source                 = "../../modules/database"
  name                   = var.name
  db_name                = "appdb"
  username               = local.db_creds.username
  password               = local.db_creds.password
  db_subnet_ids          = module.networking.private_subnets
  vpc_security_group_ids = [module.networking.db_sg_id]
  tags                   = { Name = "web-app-db" }
}

module "monitoring" {
  source      = "../../modules/monitoring"
  name        = var.name
  tags        = { Name = "web-app-monitoring" }
  asg_name    = module.compute.asg_name
  alert_email = var.alert_email
}