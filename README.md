# lizferLinux on containers

For this small project, I want to bring back the [lizferLinux Wordpress blog](https://github.com/l12f3r/lizferLinux) (who went down due to lack of payment to Digital Ocean), but without all the hassle of configuring a LAMP environment - I will provision a Wordpress environment using containers (an AWS ECS cluster with Fargate), consuming from MariaDB (in AWS Aurora).

### 1. Creating the network environment

A public VPC must be created, for the Wordpress web environment be accessed. This is quite similar to what I did on the [PostgreSQL on Terraform challenge](https://github.com/l12f3r/postgresql-rds-dbeaver#1-preparing-the-environment-and-vpc): I'll use a Terraform module to obtain predefined network settings. On `main.tf`, the following code must be set:

```terraform
#main.tf
data "aws_availability_zones" "azs" {
  all_availability_zones = true

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = var.vpcName
  cidr = var.vpcCIDRBlock
  azs = data.aws_availability_zones.azs.names
  private_subnets = var.privSubCIDRBlocks #must be set as list(string) type on variables.tf
  public_subnets = var.pubSubCIDRBlocks #must be set as list(string) type on variables.tf
  enable_dns_hostnames = true
  enable_dns_support = true
}
```