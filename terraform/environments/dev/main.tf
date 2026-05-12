# Dev environment - Creates VPC + EKS cluster
# This file USES the modules we created

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration (where to store state)
  # For now, we'll use local state (file on your computer)
  # Later we'll migrate to S3
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# -----------------------------------------------------------------------------
# LOCAL VARIABLES (Computed values)
# -----------------------------------------------------------------------------

locals {
  cluster_name = "${var.project_name}-${var.environment}-cluster"
  vpc_name     = "${var.project_name}-${var.environment}-vpc"

  # Calculate private and public subnet CIDRs
  # 10.0.0.0/19 = 8,192 addresses per subnet
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 3, 0), # 10.0.0.0/19
    cidrsubnet(var.vpc_cidr, 3, 1), # 10.0.32.0/19
    cidrsubnet(var.vpc_cidr, 3, 2), # 10.0.64.0/19
  ]

  # 10.0.96.0/19 = 8,192 addresses per subnet
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 3, 3), # 10.0.96.0/19
    cidrsubnet(var.vpc_cidr, 3, 4), # 10.0.128.0/19
    cidrsubnet(var.vpc_cidr, 3, 5), # 10.0.160.0/19
  ]
}

# -----------------------------------------------------------------------------
# CREATE VPC (Network)
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  vpc_name        = local.vpc_name
  vpc_cidr        = var.vpc_cidr
  azs             = var.availability_zones
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  tags = merge(
    var.tags,
    {
      Name = local.vpc_name
    }
  )
}

# -----------------------------------------------------------------------------
# CREATE EKS CLUSTER (Kubernetes)
# -----------------------------------------------------------------------------

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name       = local.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Node configuration
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  tags = merge(
    var.tags,
    {
      Name = local.cluster_name
    }
  )

  # EKS cluster depends on VPC being created first
  depends_on = [module.vpc]
}

module "github_oidc" {
  source = "../../modules/github-oidc"
}
