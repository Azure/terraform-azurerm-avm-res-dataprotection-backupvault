output "backup_vault_both_id" {
  description = "The ID of the Backup Vault with both System and User-Assigned Identities"
  value       = module.backup_vault_both_identities.resource_id
}

output "backup_vault_both_identity_principal_id" {
  description = "The System-Assigned Principal ID for the Both-Identity Backup Vault"
  value       = module.backup_vault_both_identities.identity_principal_id
}

output "backup_vault_user_only_id" {
  description = "The ID of the Backup Vault with User-Assigned Identity only"
  value       = module.backup_vault_user_assigned_only.resource_id
}

output "backup_vault_user_only_identity_principal_id" {
  description = "The Principal ID for the Identity of the User-Only Backup Vault (should be null since only user-assigned)"
  value       = module.backup_vault_user_assigned_only.identity_principal_id
}

output "user_assigned_identity_client_id" {
  description = "The Client ID of the User-Assigned Identity"
  value       = azurerm_user_assigned_identity.backup_vault_identity.client_id
}

output "user_assigned_identity_id" {
  description = "The ID of the User-Assigned Identity created for the backup vault"
  value       = azurerm_user_assigned_identity.backup_vault_identity.id
}

output "user_assigned_identity_principal_id" {
  description = "The Principal ID of the User-Assigned Identity"
  value       = azurerm_user_assigned_identity.backup_vault_identity.principal_id
}
