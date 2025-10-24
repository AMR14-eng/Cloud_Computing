resource "aws_vpc" "this" {
  cidr_block = var.cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = var.name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = length(var.azs) > 0 ? element(var.azs, 0) : null
  tags = { Name = "${var.name}-public-${replace(each.value, "/", "-")}" }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-rt" }
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "pub_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.main.id
}
