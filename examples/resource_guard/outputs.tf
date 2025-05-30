# Output the backup vault ID
output "backup_vault_id" {
  description = "The ID of the backup vault"
  value       = module.backup_vault.backup_vault_id
}

# Output the Resource Guard ID
output "resource_guard_id" {
  description = "The ID of the Resource Guard"
  value       = module.backup_vault.resource_guard_id
}
