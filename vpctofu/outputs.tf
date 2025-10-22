output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID de la Subnet creada"
  value       = aws_subnet.main.id
}

output "igw_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.gw.id
}

output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "ec2_public_ip" {
  description = "Dirección IP pública del servidor web"
  value       = aws_instance.web_server.public_ip
}
