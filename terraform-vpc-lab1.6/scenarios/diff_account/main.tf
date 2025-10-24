terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Requester: tu cuenta (por defecto)
provider "aws" {
  region = "us-east-1"
}

# Accepter: asumimos un role en la otra cuenta para automatizar la aceptación
provider "aws" {
  alias = "accepter"
  region = "us-east-1"
  assume_role {
    role_arn = var.accepter_role_arn
  }
}

module "vpc_requester" {
  source = "../../modules/vpc"
  name = "arleth-lab-vpc-requester"
  cidr = "10.50.0.0/16"
  public_subnets = ["10.50.1.0/24"]
}

# NOTA: Si quieres crear la VPC del otro account desde aquí, necesitarás
# permisos en la otra cuenta. En este ejemplo asumimos que la VPC del
# accepter ya existe: su id y route table id deben proporcionarse.
variable "accepter_vpc_id" { type = string default = "" }
variable "accepter_route_table_id" { type = string default = "" }

# Peering (creado en tu cuenta como requester)
resource "aws_vpc_peering_connection" "requester_peer" {
  vpc_id = module.vpc_requester.vpc_id
  peer_vpc_id = var.accepter_vpc_id
  peer_owner_id = var.accepter_account_id
  auto_accept = false
  tags = { Name = "peer-requester-to-accepter" }
}

# Aceptar el peering usando el provider 'accepter' que asume role en la otra cuenta
resource "aws_vpc_peering_connection_accepter" "accepter_accept" {
  provider = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.requester_peer.id
  auto_accept = true
}

# Rutas en requester
resource "aws_route" "requester_to_accepter" {
  route_table_id = module.vpc_requester.route_table_id
  destination_cidr_block = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.requester_peer.id
}

# Nota: La ruta del lado 'accepter' debe ser creada en la otra cuenta. Si el role que asumes
# tiene permisos para crear rutas, puedes crearla aquí usando el provider 'accepter'.
resource "aws_route" "accepter_to_requester" {
  provider = aws.accepter
  route_table_id = var.accepter_route_table_id
  destination_cidr_block = module.vpc_requester.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.requester_peer.id
}

variable "accepter_role_arn" { type = string }
variable "accepter_account_id" { type = string }
variable "accepter_cidr" { type = string }
