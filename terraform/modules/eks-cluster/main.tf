# This module creates an EKS (Elastic Kubernetes Service) cluster
# Think of this as building a school with classrooms, offices, and a playground

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR EKS CLUSTER (Like the principal's credentials)
# -----------------------------------------------------------------------------

# The cluster needs permission to manage AWS resources
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  # Trust policy: Allow EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.cluster_name}-cluster-role"
    },
    var.tags
  )
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# -----------------------------------------------------------------------------
# SECURITY GROUP FOR CLUSTER (Firewall rules)
# -----------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic (cluster needs to talk to AWS services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name = "${var.cluster_name}-cluster-sg"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow worker nodes to communicate with cluster API server
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  description              = "Allow worker nodes to communicate with cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
}

# -----------------------------------------------------------------------------
# CREATE THE EKS CLUSTER (The school building itself!)
# -----------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    # Cluster API endpoint accessibility
    endpoint_private_access = true  # Accessible from inside VPC
    endpoint_public_access  = true  # Accessible from internet (for kubectl)
    
    subnet_ids = concat(
      var.private_subnet_ids,
      var.public_subnet_ids
    )

    security_group_ids = [aws_security_group.cluster.id]
  }

  # Enable control plane logging (good for troubleshooting)
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = merge(
    {
      Name = var.cluster_name
    },
    var.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_policy,
  ]
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR WORKER NODES (Like teacher credentials)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.cluster_name}-node-role"
    },
    var.tags
  )
}

# Attach required policies for worker nodes
resource "aws_iam_role_policy_attachment" "nodes_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# -----------------------------------------------------------------------------
# SECURITY GROUP FOR WORKER NODES (Firewall for the workers)
# -----------------------------------------------------------------------------

resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name                                        = "${var.cluster_name}-node-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
}

# Allow worker nodes to receive traffic from cluster control plane
resource "aws_security_group_rule" "nodes_cluster_ingress" {
  description              = "Allow worker nodes to receive traffic from cluster"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
}

# -----------------------------------------------------------------------------
# MANAGED NODE GROUP (The actual worker computers)
# -----------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids

  # Scaling configuration
  scaling_config {
    desired_size = var.node_desired_size  # How many nodes you want
    min_size     = var.node_min_size      # Minimum (when quiet)
    max_size     = var.node_max_size      # Maximum (when busy)
  }

  # Update configuration (how to roll out updates)
  update_config {
    max_unavailable = 1  # Only update 1 node at a time
  }

  # Instance types and capacity
  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"  # Use on-demand instances (not spot)

  # Disk size for each node
  disk_size = 20  # GB (enough for system + pulling Docker images)

  # Use latest AMI (Amazon Machine Image)
  ami_type = "AL2_x86_64"  # Amazon Linux 2

  tags = merge(
    {
      Name = "${var.cluster_name}-node-group"
    },
    var.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_registry_policy,
  ]

  # Ensure node group updates don't interrupt workloads
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# EKS ADD-ONS (Enhanced features)
# -----------------------------------------------------------------------------

# VPC CNI - Networking plugin (gives pods IP addresses)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = "v1.16.0-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = null

  tags = var.tags
}

# CoreDNS - DNS resolution inside cluster
resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  addon_version     = "v1.11.1-eksbuild.4"
  resolve_conflicts = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy - Network proxy on each node
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "kube-proxy"
  addon_version     = "v1.29.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  tags = var.tags
}

# EBS CSI Driver - For persistent volumes (disk storage)
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.28.0-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# -----------------------------------------------------------------------------
# IAM ROLE FOR EBS CSI DRIVER (Needed for persistent storage)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ebs_csi_driver_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.main.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume.json

  tags = merge(
    {
      Name = "${var.cluster_name}-ebs-csi-driver"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# -----------------------------------------------------------------------------
# OIDC PROVIDER (For IRSA - IAM Roles for Service Accounts)
# -----------------------------------------------------------------------------

# This allows Kubernetes pods to assume IAM roles
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    {
      Name = "${var.cluster_name}-oidc-provider"
    },
    var.tags
  )
}
