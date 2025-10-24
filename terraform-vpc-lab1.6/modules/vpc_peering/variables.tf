variable "name" { type = string }
variable "requester_vpc_id" { type = string }
variable "requester_route_table_id" { type = string }
variable "requester_cidr" { type = string }

variable "accepter_vpc_id" { type = string }
variable "accepter_route_table_id" { type = string }
variable "accepter_cidr" { type = string }

variable "peer_region" { type = string default = "" } # empty for same region
variable "peer_owner_id" { type = string default = "" } # for cross-account
variable "auto_accept" { type = bool default = false }
