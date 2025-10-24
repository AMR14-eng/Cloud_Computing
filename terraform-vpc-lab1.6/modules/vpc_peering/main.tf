resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_region   = var.peer_region != "" ? var.peer_region : null
  peer_owner_id = var.peer_owner_id != "" ? var.peer_owner_id : null
  auto_accept   = var.auto_accept
  tags = { Name = var.name }
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  count = var.auto_accept ? 0 : 1
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept = true
}

# Routes: requester -> accepter
resource "aws_route" "requester_to_accepter" {
  route_table_id = var.requester_route_table_id
  destination_cidr_block = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# Routes: accepter -> requester
resource "aws_route" "accepter_to_requester" {
  route_table_id = var.accepter_route_table_id
  destination_cidr_block = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
