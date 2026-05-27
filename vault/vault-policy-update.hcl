# Policy for fleet-services role
# This defines what secrets Kubernetes pods with "fleet-services" role can access

# Allow reading Kafka credentials
path "secret/data/kafka/*" {
  capabilities = ["read", "list"]
}

# Allow reading Keycloak client credentials
path "secret/data/keycloak/*" {
  capabilities = ["read", "list"]
}