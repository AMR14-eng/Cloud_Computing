terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" { region = "us-east-1" }

module "vpc_a" {
  source = "../../modules/vpc"
  name = "arleth-lab-vpc-a"
  cidr = "10.10.0.0/16"
  public_subnets = ["10.10.1.0/24"]
}

module "vpc_b" {
  source = "../../modules/vpc"
  name = "arleth-lab-vpc-b"
  cidr = "10.20.0.0/16"
  public_subnets = ["10.20.1.0/24"]
}

module "peering_ab" {
  source = "../../modules/vpc_peering"
  name = "peering-arleth-a-b"
  requester_vpc_id = module.vpc_a.vpc_id
  requester_route_table_id = module.vpc_a.route_table_id
  requester_cidr = module.vpc_a.vpc_cidr

  accepter_vpc_id = module.vpc_b.vpc_id
  accepter_route_table_id = module.vpc_b.route_table_id
  accepter_cidr = module.vpc_b.vpc_cidr

  auto_accept = true
}
