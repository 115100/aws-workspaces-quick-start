provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "domain" {
  type = string
}

variable "auto_create_users" {
  type    = bool
  default = false
}

variable "admin_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "default_user_password" {
  type      = string
  sensitive = true
}

variable "users" {
  type = list(string)
}

locals {
  domain_name = "${var.domain}.com"
  tags = {
    (var.domain) = true
  }
}

resource "aws_directory_service_directory" "directory" {
  name     = local.domain_name
  password = var.admin_password
  size     = "Small"

  vpc_settings {
    vpc_id     = local.vpc_id
    subnet_ids = local.subnet_ids
  }

  tags = local.tags
}

locals {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
}

resource "aws_workspaces_directory" "directory" {
  directory_id = aws_directory_service_directory.directory.id
  subnet_ids   = local.subnet_ids

  workspace_access_properties {
    device_type_chromeos   = "ALLOW"
    device_type_linux      = "ALLOW"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_android    = "DENY"
    device_type_ios        = "DENY"
    device_type_zeroclient = "DENY"
  }

  tags = local.tags

  depends_on = [aws_iam_role.workspace_default]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                             = var.domain
  cidr                             = "10.0.0.0/16"
  azs                              = ["${var.region}a", "${var.region}b"]
  public_subnets                   = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_dns_hostnames             = true
  enable_dhcp_options              = true
  dhcp_options_domain_name_servers = aws_directory_service_directory.directory.dns_ip_addresses

  tags = merge(local.tags, {
    Name = var.domain
  })
  public_subnet_tags = merge(local.tags, {
    Name = "${var.domain}-public"
  })
  vpc_tags = merge(local.tags, {
    Name = "${var.domain}-vpc"
  })
}

output "directory_id" {
  value = aws_workspaces_directory.directory.id
}

output "registration_code" {
  value = aws_workspaces_directory.directory.registration_code
}
