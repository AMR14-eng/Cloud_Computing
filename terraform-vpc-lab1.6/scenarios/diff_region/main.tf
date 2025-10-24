terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" { alias = "us" , region = "us-east-1" }
provider "aws" { alias = "west", region = "us-west-2" }

module "vpc_us" {
  source = "../../modules/vpc"
  providers = { aws = aws.us }
  name = "arleth-lab-vpc-us"
  cidr = "10.30.0.0/16"
  public_subnets = ["10.30.1.0/24"]
}

module "vpc_west" {
  source = "../../modules/vpc"
  providers = { aws = aws.west }
  name = "arleth-lab-vpc-west"
  cidr = "10.40.0.0/16"
  public_subnets = ["10.40.1.0/24"]
}

resource "aws_vpc_peering_connection" "peering_us_west" {
  provider = aws.us
  vpc_id = module.vpc_us.vpc_id
  peer_vpc_id = module.vpc_west.vpc_id
  peer_region = "us-west-2"
  auto_accept = false
  tags = { Name = "peering-us-west" }
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider = aws.west
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_west.id
  auto_accept = true
}

resource "aws_route" "us_to_west" {
  provider = aws.us
  route_table_id = module.vpc_us.route_table_id
  destination_cidr_block = module.vpc_west.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_west.id
}

resource "aws_route" "west_to_us" {
  provider = aws.west
  route_table_id = module.vpc_west.route_table_id
  destination_cidr_block = module.vpc_us.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_us_west.id
}
