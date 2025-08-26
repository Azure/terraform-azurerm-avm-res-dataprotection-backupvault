output "backup_vault_id" {
  description = "The ID of the backup vault"
  value       = module.backup_vault.backup_vault_id
}

output "backup_vault_name" {
  description = "The name of the backup vault"
  value       = module.backup_vault.backup_vault_name
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.example.id
}

output "key_vault_key_id" {
  description = "The ID of the Key Vault key"
  value       = azurerm_key_vault_key.example.id
}

output "user_assigned_identity_id" {
  description = "The ID of the user assigned managed identity"
  value       = azurerm_user_assigned_identity.example.id
}