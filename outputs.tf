output "backup_policy_blob_storage_id" {
  description = "The ID of the Blob Storage Backup Policy."
  value       = var.blob_backup_instance_name != null && length(azurerm_data_protection_backup_policy_blob_storage.this) > 0 ? azurerm_data_protection_backup_policy_blob_storage.this[0].id : null
}

output "backup_policy_id" {
  description = "The ID of the Backup Policy."
  value       = var.blob_backup_instance_name != null && length(azurerm_data_protection_backup_policy_blob_storage.this) > 0 ? azurerm_data_protection_backup_policy_blob_storage.this[0].id : null
}

output "backup_vault_id" {
  description = "The ID of the Backup Vault."
  value       = azurerm_data_protection_backup_vault.this.id
}

output "blob_backup_instance_id" {
  description = "The ID of the Blob Backup Instance."
  value       = var.blob_backup_instance_name != null && length(azurerm_data_protection_backup_instance_blob_storage.blob_backup_instance) > 0 ? azurerm_data_protection_backup_instance_blob_storage.blob_backup_instance[0].id : null
}

output "identity_principal_id" {
  description = "The Principal ID for the Service Principal associated with the Identity of this Backup Vault."
  value       = try(azurerm_data_protection_backup_vault.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The Tenant ID for the Service Principal associated with the Identity of this Backup Vault."
  value       = try(azurerm_data_protection_backup_vault.this.identity[0].tenant_id, null)
}

output "lock_id" {
  description = "The resource ID of the management lock (if created)"
  # if you used count = var.lock != null ? 1 : 0 on your lock:
  value = try(azurerm_management_lock.this[0].id, "")
}

output "postgresql_flexible_backup_instance_id" {
  description = "The ID of the created PostgreSQL Flexible Server Backup Instance."
  value       = try(azurerm_data_protection_backup_instance_postgresql_flexible_server.postgresql_flexible_backup_instance[0].id, null)
}

output "postgresql_flexible_backup_policy_id" {
  description = "The ID of the created PostgreSQL Flexible Server Backup Policy."
  value       = try(azurerm_data_protection_backup_policy_postgresql_flexible_server.postgresql_flexible_backup_policy[0].id, null)
}

output "resource_id" {
  description = "The ID of the Backup Vault"
  value       = azurerm_data_protection_backup_vault.this.id
}

output "vault_id" {
  description = "The resource ID of the Backup Vault"
  value       = azurerm_data_protection_backup_vault.this.id
}
