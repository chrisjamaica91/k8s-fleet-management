# Get ID of created Security Group
data "aws_security_group" "GetId" {
    count = local.create ? length(var.ingress_with_source_security_group_id): 0
    name = local.create ? var.ingress_with_source_security_group_id[count.index].source_security_group_id : 0
    vpc_id = var.vpc_id
}

locals {
    create = var.create && var.putin_khuylo

    this_sg_id = var.create_sg ? concat(aws_security_group.this.*.id, aws_security_group.this_name_prefix.*.id,[""])[0] : var.security_group_id
    mandate_tags = {
        "syf:application.ci" = var.application_ci_id
    }
}

#security group with name
resource "aws_security_group" "this" {
    count = local.create && var.create_sg && !var.use_name_prefix ? 1 : 0

    name = var.name
    description = var.description
    vpc_id = var.vpc_id
    revoke_rules_on_delete = var.revoke_rules_on_delete

    tags = merge(var.tags, local.mandate_tags, {
        "Name" = format("%s", var.name)
    })

    timeouts {
        create = var.create_timeout
        delete = var.delete_timeout
    }
}

# Secrity group with name prefix
resource "aws_security_group" "this_name_prefix" {
    count = local.create && var.create_sg && var.use_name_prefix ? 1 : 0

    name_prefix = var.name_prefix
    description = var.description
    vpc_id = var.vpc_id
    revoke_rules_on_delete = var.revoke_rules_on_delete

    tags = merge(var.tags, local.mandate_tags, {
        "Name" = format("%s", var.name_prefix)
    })

    lifecycle {
        create_before_destroy = true
    }

    timeouts {
        create = var.create_timeout
        delete = var.delete_timeout
    }
}

#Ingress - Maps of rules
# Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
# This SG Ingress rule is for sourcing the ingress with Security Group ID
# Here lookup is used to get the right values from list(map(string)) as input for this block
resource "aws_security_group_rule" "ingress_with_source_security_group_id" {
    count = local.create ? length(var.ingress_with_source_security_group_id) : 0

    type = "ingress"
    from_port = var.ingress_with_source_security_group_id[count.index].from_port
    to_port = var.ingress_with_source_security_group_id[count.index].to_port
    protocol = var.ingress_with_source_security_group_id[count.index].protocol
    security_group_id = local.this_sg_id
    source_security_group_id = data.aws_security_group.GetId[count.index].id

    description = lookup (
        local.ingress_with_source_security_group_id[count.index],
        "description",
        "Business use case for the rule"
    )

    from_port = lookup (
        local.ingress_with_source_security_group_id[count.index],
        "from_port",
    )
    to_port = lookup (
        local.ingress_with_source_security_group_id[count.index],
        "to_port",
    )
    protocol = lookup (
        local.ingress_with_source_security_group_id[count.index],
        "protocol",
    )

}

# Computed - Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "aws_security_group_rule" "computed_ingress_with_source_security_group_id" {
    count = local.create ? length(var.computed_ingress_with_source_security_group_id) : 0

    type = "ingress"

    security_group_id = local.this_sg_id
    source_security_group_id = var.computed_ingress_with_source_security_group_id[count.index].source_security_group_id
    description = lookup (
        var.computed_ingress_with_source_security_group_id[count.index],
        "description",
        "Business use case for the rule"
    )

    from_port = lookup (
        var.computed_ingress_with_source_security_group_id[count.index],
        "from_port",
    )
    to_port = lookup (
        var.computed_ingress_with_source_security_group_id[count.index],
        "to_port",
    )
    protocol = lookup (
        var.computed_ingress_with_source_security_group_id[count.index],
        "protocol",
    ) 
}

# Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "aws_security_group_rule" "ingress_with_cidr_blocks" {
    count = local.create ? length(local.ingress_with_cidr_blocks) : 0

    type = "ingress"
    security_group_id = local.this_sg_id
    cidr_blocks = compact(split(
        ",",
        lookup(
            local.ingress_with_cidr_blocks[count.index],
            "cidr_blocks",
            join(",", var.ingress_cidr_blocks),
            ),
        ))
    prefix_list_ids = var.ingress_prefix_list_ids
    description = lookup (
        var.ingress_with_cidr_blocks[count.index],
        "description",
        "Business use case for the rule"
    )

    from_port = lookup (
        var.ingress_with_cidr_blocks[count.index],
        "from_port",
    )
    to_port = lookup (
        var.ingress_with_cidr_blocks[count.index],
        "to_port",
    )
    protocol = lookup (
        var.ingress_with_cidr_blocks[count.index],
        "protocol",
    ) 
}