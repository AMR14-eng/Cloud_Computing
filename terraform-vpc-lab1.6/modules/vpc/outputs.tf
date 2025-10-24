output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = var.cidr }
output "route_table_id" { value = aws_route_table.main.id }
output "public_subnet_ids" { value = values(aws_subnet.public).*.id }
