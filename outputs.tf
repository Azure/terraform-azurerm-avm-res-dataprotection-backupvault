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

output "resource_id" {
  description = "The ID of the Backup Vault"
  value       = azurerm_data_protection_backup_vault.this.id
}
