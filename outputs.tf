# Identity Outputs

# Backup Instance Outputs
output "backup_instance_ids" {
  description = "Map of backup instance IDs by instance key."
  value = merge(
    { for k, v in azapi_resource.backup_instance_disk : k => v.id },
    { for k, v in azapi_resource.backup_instance_blob_storage : k => v.id },
    { for k, v in azapi_resource.backup_instance_kubernetes_cluster : k => v.id },
    { for k, v in azapi_resource.backup_instance_postgresql : k => v.id },
    { for k, v in azapi_resource.backup_instance_postgresql_flexible_server : k => v.id }
  )
}

output "backup_policy_ids" {
  description = "Map of backup policy IDs by policy key."
  value = merge(
    { for k, v in azapi_resource.backup_policy_disk : k => v.id },
    { for k, v in azapi_resource.backup_policy_blob_storage : k => v.id },
    { for k, v in azapi_resource.backup_policy_kubernetes_cluster : k => v.id },
    { for k, v in azapi_resource.backup_policy_postgresql : k => v.id },
    { for k, v in azapi_resource.backup_policy_postgresql_flexible_server : k => v.id }
  )
}

output "backup_vault_id" {
  description = "The ID of the Backup Vault."
  value       = azapi_resource.backup_vault.id
}

output "backup_vault_name" {
  description = "The name of the Backup Vault."
  value       = azapi_resource.backup_vault.name
}

output "blob_backup_instance_id" {
  description = "(DEPRECATED) The ID of the Blob Backup Instance. Use backup_instance_ids instead."
  value       = try(values(azapi_resource.backup_instance_blob_storage)[0].id, null)
}

output "blob_backup_instance_ids" {
  description = "Map of blob backup instance IDs by instance key."
  value       = { for k, v in azapi_resource.backup_instance_blob_storage : k => v.id }
}

output "blob_backup_policy_ids" {
  description = "Map of blob backup policy IDs by policy key."
  value       = { for k, v in azapi_resource.backup_policy_blob_storage : k => v.id }
}

output "customer_managed_key_id" {
  description = "The ID of the Customer Managed Key configuration (if enabled)"
  value       = try(azapi_update_resource.cmk[0].id, null)
}

output "disk_backup_instance_ids" {
  description = "Map of disk backup instance IDs by instance key."
  value       = { for k, v in azapi_resource.backup_instance_disk : k => v.id }
}

output "disk_backup_policy_ids" {
  description = "Map of disk backup policy IDs by policy key."
  value       = { for k, v in azapi_resource.backup_policy_disk : k => v.id }
}

output "identity_principal_id" {
  description = "The Principal ID for the Service Principal associated with the Identity of this Backup Vault."
  value       = try(azapi_resource.backup_vault.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The Tenant ID for the Service Principal associated with the Identity of this Backup Vault."
  value       = try(azapi_resource.backup_vault.identity[0].tenant_id, null)
}

output "kubernetes_backup_instance_ids" {
  description = "Map of Kubernetes backup instance IDs by instance key."
  value       = { for k, v in azapi_resource.backup_instance_kubernetes_cluster : k => v.id }
}

output "kubernetes_backup_policy_ids" {
  description = "Map of Kubernetes backup policy IDs by policy key."
  value       = { for k, v in azapi_resource.backup_policy_kubernetes_cluster : k => v.id }
}

output "lock_id" {
  description = "The resource ID of the management lock (if created)"
  value       = try(azapi_resource.lock[0].id, "")
}

output "postgresql_backup_instance_ids" {
  description = "Map of PostgreSQL backup instance IDs by instance key."
  value       = { for k, v in azapi_resource.backup_instance_postgresql : k => v.id }
}

output "postgresql_backup_policy_ids" {
  description = "Map of PostgreSQL backup policy IDs by policy key."
  value       = { for k, v in azapi_resource.backup_policy_postgresql : k => v.id }
}

output "postgresql_flexible_backup_instance_id" {
  description = "(DEPRECATED) The ID of the created PostgreSQL Flexible Server Backup Instance. Use backup_instance_ids instead."
  value       = try(values(azapi_resource.backup_instance_postgresql_flexible_server)[0].id, null)
}

output "postgresql_flexible_backup_instance_ids" {
  description = "Map of PostgreSQL Flexible backup instance IDs by instance key."
  value       = { for k, v in azapi_resource.backup_instance_postgresql_flexible_server : k => v.id }
}

output "postgresql_flexible_backup_policy_id" {
  description = "(DEPRECATED) The ID of the created PostgreSQL Flexible Server Backup Policy. Use backup_policy_ids instead."
  value       = try(values(azapi_resource.backup_policy_postgresql_flexible_server)[0].id, null)
}

output "postgresql_flexible_backup_policy_ids" {
  description = "Map of PostgreSQL Flexible backup policy IDs by policy key."
  value       = { for k, v in azapi_resource.backup_policy_postgresql_flexible_server : k => v.id }
}

output "resource_guard_id" {
  description = "The ID of the Resource Guard (if enabled)"
  value       = try(azapi_resource.resource_guard[0].id, null)
}

output "resource_guard_name" {
  description = "The name of the Resource Guard (if enabled)"
  value       = try(azapi_resource.resource_guard[0].name, null)
}

output "resource_id" {
  description = "The ID of the Backup Vault"
  value       = azapi_resource.backup_vault.id
}

output "vault_id" {
  description = "The resource ID of the Backup Vault"
  value       = azapi_resource.backup_vault.id
}
