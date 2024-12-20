output "cluster_id" {
  description = "The Kubernetes Managed Cluster ID."
  value       = module.aks_cluster.id
}

# output "client_certificate" {
#   description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster."
#     value =  module.aks_cluster.kube_config.0.client_certificate
#   sensitive   = true
# }

output "kube_config" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools."
  value       = module.aks_cluster.kube_config_raw
  sensitive   = true
}

output "private_ssh_key" {
  value     = module.ssh_key.private_key_data
  sensitive = true
}

# output "vm_public_ip" {
#   value = module.virtual_machine.public_ip
# }
output "key_vault_secrets_provider_identity_object_id" {
  value = module.aks_cluster.key_vault_secrets_provider_identity_object_id
}
output "key_vault_secrets_provider_identity_client_id" {
  value = module.aks_cluster.key_vault_secrets_provider_identity_client_id
}
output "aks_cluster_oidc_issuer_url" {
  value = module.aks_cluster.oidc_issuer_url
}
output "key_vault_secrets_provider_user_assigned_identity_id" {
  value = module.aks_cluster.key_vault_secrets_provider_user_assigned_identity_id
}