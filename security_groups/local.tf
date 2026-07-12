locals {
    ingress_with_source_security_group_id = [for i in var.ingress_with_source_security_group_id : i if !contains(local.blacklist_port, i.from_port)]
    ingress_with_cidr_blocks = [for i in var.ingress_with_cidr_blocks : i if !contains(local.blacklist_port, i.from_port)]
}