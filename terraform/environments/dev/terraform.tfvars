# Actual values for dev environment variables
# These override the defaults in variables.tf

aws_region   = "us-east-2"
environment  = "dev"
project_name = "fleet"

# Kubernetes version
cluster_version = "1.30"

# Network configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = [
  "us-east-2a",
  "us-east-2b",
  "us-east-2c"
]

# Worker node configuration
node_instance_types = ["t3.medium"]
node_desired_size   = 3  # Increased to fit Vault + Keycloak + services
node_min_size       = 2
node_max_size       = 4

# Tags
tags = {
  Project     = "k8s-fleet-management"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "chris"
}
