variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (like a street address range)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones (like different neighborhoods)"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (where your apps run)"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (where load balancers live)"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
