#security group
variable "create" {
    description = "Whether to create a security group and all rules"
    type = bool
    default = true
}

variable "create_sg" {
    description = "Whether to create a security group"
    type = bool
    default = true
}

variable "application_ci_id" {
    description = "ID of the application CI for tagging purposes"
    type = string
    default = ""
    nullable = false
}

variable "security_group_id" {
    description = "ID of an existing security group to use instead of creating a new one. If this is set, 'create' and 'create_sg' will be ignored."
    type = string
    default = null
}

variable "vpc_id" {
    description = "Id of the VPC where the security group will be created"
    type = string
    nullable = false
}

variable "name" {
    description = "Name of the security group"
    type = string
    default = ""
    validation {
        condition = !startswith(var.name, "sg")
        error_message = "Security group name cannot start with 'sg' as it is reserved by AWS for security group IDs."
    }
}

variable "description" {
    description = "Description of the security group"
    type = string
    default = "Managed by Terraform"

}

variable "revoke_rules_on_delete" {
    description = "Whether to revoke all rules before deleting the security group"
    type = bool
    default = false
}

variable "tags" {
    description = "A mapping of tags to assign to security group"
    type = map(string)
    default = {}
}

# ingress

variable "ingress_rules" {
    description = "List of ingress rules to create by name"
    type = list(string)
    default = []
}

variable "ingress_with_self" {
    description = "List of ingress rules to create where 'self' is defined"
    type = list(map(string))
    default = []
}

variable "ingress_with_cidr_blocks" {
    description = "List of ingress rules to create where 'cidr_blocks' is defined"
    type = list(map(string))
    default = []
    validation {
        condition = [for i in var.ingress_with_cidr_blocks : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.ingress_with_cidr_blocks : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "ingress_with_ipv6_cidr_blocks" {
    description = "List of ingress rules to create where 'ipv6_cidr_blocks' is defined"
    type = list(map(string))
    default = []
    validation {
        condition = [for i in var.ingress_with_ipv6_cidr_blocks : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.ingress_with_ipv6_cidr_blocks : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "ingress_cidr_blocks" {
    description = "List of IPv4 CIDR ranges to use on all ingress rules"
    type = list(string)
    default = []
    validation {
        condition = [for i in var.ingress_cidr_blocks : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.ingress_cidr_blocks : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "ingress_ipv6_cidr_blocks" {
    description = "List of IPv6 CIDR ranges to use on all ingress rules"
    type = list(string)
    default = []
    validation {
        condition = [for i in var.ingress_ipv6_cidr_blocks : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.ingress_ipv6_cidr_blocks : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "ingress_prefix_list_ids" {
    description = "List of prefix list IDs (for allowing access to VPC endpoints) to use on all ingress rules"
    type = list(string)
    default = []
    validation {
        condition = [for i in var.ingress_prefix_list_ids : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.ingress_prefix_list_ids : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

# Computed Ingress
variable "computed_ingress_rules" {
    description = "List of computed ingress rules to create by name. This is for rules that are computed from other resources, such as ALB or NLB security groups."
    type = list(string)
    default = []
    validation = {
        condition = [for i in var.computed_ingress_rules : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.computed_ingress_rules : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "computed_ingress_with_self" {
    description = "List of computed ingress rules to create where 'self' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'self' is defined."
    type = list(map(string))
    default = []
    validation = {
        condition = [for i in var.computed_ingress_with_self : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.computed_ingress_with_self : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "computed_ingress_with_cidr_blocks" {
    description = "List of computed ingress rules to create where 'cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'cidr_blocks' is defined."
    type = list(map(string))
    default = []
    validation = {
        condition = [for i in var.computed_ingress_with_cidr_blocks : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.computed_ingress_with_cidr_blocks : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "computed_ingress_with_ipv6_cidr_blocks" {
    description = "List of computed ingress rules to create where 'ipv6_cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'ipv6_cidr_blocks' is defined."
    type = list(map(string))
    default = []
    validation = {
        condition = [for i in var.computed_ingress_with_ipv6_cidr_blocks : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.computed_ingress_with_ipv6_cidr_blocks : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "computed_ingress_with_source_security_group_id" {
    description = "List of computed ingress rules to create where 'source_security_group_id' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'source_security_group_id' is defined."
    type = list(map(string))
    default = []
    validation = {
        condition = [for i in var.computed_ingress_with_source_security_group_id : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.computed_ingress_with_source_security_group_id : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "computed_ingress_with_prefix_list_ids" {
    description = "List of computed ingress rules to create where 'prefix_list_ids' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'prefix_list_ids' is defined."
    type = list(map(string))
    default = []
    validation = {
        condition = [for i in var.computed_ingress_with_prefix_list_ids : i.from_port if contains(local.blacklist_port, i.from_port)] == [] &&  [for i in var.computed_ingress_with_prefix_list_ids : i.protocol if contains(["ALL"], upper(i.protocol))] == [] ? true : false
        error_message = "These ports are not allowed ${local.blacklist_port} and protocol cannot be ALL. Need an exception request that needs approval, but ALL protocol is not allowed."
    }
}

variable "number_of_computed_ingress_rules" {
    description = "Number of computed ingress rules to create. This is for rules that are computed from other resources, such as ALB or NLB security groups, where the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_ingress_with_self" {
    description = "Number of computed ingress rules to create where 'self' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'self' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_ingress_with_cidr_blocks" {
    description = "Number of computed ingress rules to create where 'cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'cidr_blocks' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_ingress_with_ipv6_cidr_blocks" {
    description = "Number of computed ingress rules to create where 'ipv6_cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'ipv6_cidr_blocks' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_ingress_with_source_security_group_id" {
    description = "Number of computed ingress rules to create where 'source_security_group_id' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'source_security_group_id' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_ingress_with_prefix_list_ids" {
    description = "Number of computed ingress rules to create where 'prefix_list_ids' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'prefix_list_ids' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

# Egress
variable "egress_rules" {
    description = "List of egress rules to create by name"
    type = list(string)
    default = []
}

variable "egress_with_self" {
    description = "List of egress rules to create where 'self' is defined"
    type = list(map(string))
    default = []
}

variable "egress_with_cidr_blocks" {
    description = "List of egress rules to create where 'cidr_blocks' is defined"
    type = list(map(string))
    default = []
}

variable "egress_with_ipv6_cidr_blocks" {
    description = "List of egress rules to create where 'ipv6_cidr_blocks' is defined"
    type = list(map(string))
    default = []
}

variable "egress_with_prefix_list_ids" {
    description = "List of prefix list IDs (for allowing access to VPC endpoints) to use on all egress rules"
    type = list(string)
    default = []
}

variable "egress_with_source_security_group_id" {
    description = "List of egress rules to create where 'source_security_group_id' is defined"
    type = list(map(string))
    default = []
}

#Computed Egress
variable "computed_egress_rules" {
    description = "List of computed egress rules to create by name. This is for rules that are computed from other resources, such as ALB or NLB security groups."
    type = list(string)
    default = []
}

variable "number_of_computed_egress_rules" {
    description = "Number of computed egress rules to create. This is for rules that are computed from other resources, such as ALB or NLB security groups, where the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_self" {
    description = "Number of computed egress rules to create where 'self' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'self' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_cidr_blocks" {
    description = "Number of computed egress rules to create where 'cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'cidr_blocks' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_ipv6_cidr_blocks" {
    description = "Number of computed egress rules to create where 'ipv6_cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'ipv6_cidr_blocks' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_source_security_group_id" {
    description = "Number of computed egress rules to create where 'source_security_group_id' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'source_security_group_id' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_prefix_list_ids" {
    description = "Number of computed egress rules to create where 'prefix_list_ids' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'prefix_list_ids' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

#Egress Rules

variable "egress_rules" {
    description = "List of egress rules to create by name"
    type = list(string)
    default = []
}

variable "egress_with_self" {
    description = "List of egress rules to create where 'self' is defined"
    type = list(map(string))
    default = []
}

variable "egress_with_cidr_blocks" {
    description = "List of egress rules to create where 'cidr_blocks' is defined"
    type = list(map(string))
    default = []
}

variable "egress_with_ipv6_cidr_blocks" {
    description = "List of egress rules to create where 'ipv6_cidr_blocks' is defined"
    type = list(map(string))
    default = []
}

variable "egress_with_prefix_list_ids" {
    description = "List of prefix list IDs (for allowing access to VPC endpoints) to use on all egress rules"
    type = list(string)
    default = []
}

variable "egress_with_source_security_group_id" {
    description = "List of egress rules to create where 'source_security_group_id' is defined"
    type = list(map(string))
    default = []
}

variable "egress_cidr_blocks" {
    description = "List of IPv4 CIDR ranges to use on all egress rules"
    type = list(string)
    default = []
}

variable "egress_ipv6_cidr_blocks" {
    description = "List of IPv6 CIDR ranges to use on all egress rules"
    type = list(string)
    default = []
}

variable "egress_prefix_list_ids" {
    description = "List of prefix list IDs (for allowing access to VPC endpoints) to use on all egress rules"
    type = list(string)
    default = []
}

# Computed Egress
variable "computed_egress_rules" {
    description = "List of computed egress rules to create by name. This is for rules that are computed from other resources, such as ALB or NLB security groups."
    type = list(string)
    default = []
}

variable "computed_egress_with_self" {
    description = "List of computed egress rules to create where 'self' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'self' is defined."
    type = list(map(string))
    default = []
}

variable "computed_egress_with_cidr_blocks" {
    description = "List of computed egress rules to create where 'cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'cidr_blocks' is defined."
    type = list(map(string))
    default = []
}

variable "computed_egress_with_source_security_group_id" {
    description = "List of computed egress rules to create where 'source_security_group_id' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'source_security_group_id' is defined."
    type = list(map(string))
    default = []
}

variable "computed_egress_with_prefix_list_ids" {
    description = "List of computed egress rules to create where 'prefix_list_ids' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'prefix_list_ids' is defined."
    type = list(map(string))
    default = []
}

# Number of computed egress rules
variable "number_of_computed_egress_rules" {
    description = "Number of computed egress rules to create. This is for rules that are computed from other resources, such as ALB or NLB security groups, where the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_self" {
    description = "Number of computed egress rules to create where 'self' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'self' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_cidr_blocks" {
    description = "Number of computed egress rules to create where 'cidr_blocks' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'cidr_blocks' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_source_security_group_id" {
    description = "Number of computed egress rules to create where 'source_security_group_id' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'source_security_group_id' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}

variable "number_of_computed_egress_with_prefix_list_ids" {
    description = "Number of computed egress rules to create where 'prefix_list_ids' is defined. This is for rules that are computed from other resources, such as ALB or NLB security groups, where 'prefix_list_ids' is defined, and the number of rules is not known until apply time."
    type = number
    default = 0
}
s