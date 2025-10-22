variable "aws_region" {
  description = "Región donde desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base para los recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block de la Subnet"
  type        = string
}

variable "availability_zone" {
  description = "Zona de disponibilidad"
  type        = string
}

variable "key_name" {
  description = "Nombre del par de llaves SSH para acceder al EC2"
  type        = string
}
