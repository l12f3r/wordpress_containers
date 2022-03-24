variable "region" {
  type = string
  description = "Region where all resources will be provisioned"
}

variable "vpcName" {
  type = string
  description = "Nametag for the VPC"
}

variable "vpcCIDRBlock" {
  type = string
  description = "CIDR Block for the VPC"
}

variable "pubSubCIDRBlocks" {
  type = list(string)
  description = "CIDR Block for the public subnet"
}