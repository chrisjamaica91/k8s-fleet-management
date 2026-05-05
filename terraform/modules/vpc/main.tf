# This module creates a VPC (Virtual Private Cloud) - your network in AWS

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create the VPC (the main network)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Allow DNS names (like order-service.local)
  enable_dns_support   = true

  tags = merge(
    {
      Name = var.vpc_name
    },
    var.tags
  )
}

# Create an Internet Gateway (door to the internet)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-igw"
    },
    var.tags
  )
}

# Create public subnets (one per availability zone)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true  # Give instances public IPs

  tags = merge(
    {
      Name                                        = "${var.vpc_name}-public-${var.azs[count.index]}"
      "kubernetes.io/role/elb"                    = "1"  # Tell Kubernetes: load balancers can use this
      "kubernetes.io/cluster/${var.vpc_name}-eks" = "shared"
    },
    var.tags
  )
}

# Create private subnets (one per availability zone)
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    {
      Name                                        = "${var.vpc_name}-private-${var.azs[count.index]}"
      "kubernetes.io/role/internal-elb"           = "1"  # Tell Kubernetes: internal load balancers only
      "kubernetes.io/cluster/${var.vpc_name}-eks" = "shared"
    },
    var.tags
  )
}

# Create Elastic IPs for NAT Gateways (static IP addresses)
resource "aws_eip" "nat" {
  count  = length(var.private_subnets)
  domain = "vpc"

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# Create NAT Gateways (allow private subnets to access internet)
# Analogy: NAT Gateway is like a mail room - private offices send mail through it
resource "aws_nat_gateway" "main" {
  count         = length(var.private_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name = "${var.vpc_name}-nat-${count.index + 1}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                       # All internet traffic
    gateway_id = aws_internet_gateway.main.id      # Goes through internet gateway
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-public-rt"
    },
    var.tags
  )
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create route tables for private subnets (one per AZ)
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"                          # All internet traffic
    nat_gateway_id = aws_nat_gateway.main[count.index].id # Goes through NAT gateway
  }

  tags = merge(
    {
      Name = "${var.vpc_name}-private-rt-${count.index + 1}"
    },
    var.tags
  )
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
