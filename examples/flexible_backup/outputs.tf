output "backup_instance_ids" {
  description = "Map of all backup instance IDs"
  value       = module.backup_vault.backup_instance_ids
}

output "backup_policy_ids" {
  description = "Map of all backup policy IDs"
  value       = module.backup_vault.backup_policy_ids
}

# Backup Vault Outputs
output "backup_vault_id" {
  description = "The ID of the backup vault"
  value       = module.backup_vault.backup_vault_id
}

output "backup_vault_name" {
  description = "The name of the backup vault"
  value       = module.backup_vault.backup_vault_name
}

output "disk_backup_instance_ids" {
  description = "Map of disk backup instance IDs"
  value       = module.backup_vault.disk_backup_instance_ids
}

output "disk_backup_policy_ids" {
  description = "Map of disk backup policy IDs"
  value       = module.backup_vault.disk_backup_policy_ids
}

output "identity_principal_id" {
  description = "The principal ID of the system assigned identity"
  value       = module.backup_vault.identity_principal_id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.example.name
}
