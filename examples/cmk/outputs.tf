output "backup_vault_id" {
  value = module.backup_vault.resource_id
}

output "backup_vault_principal_id" {
  value = module.backup_vault.identity_principal_id
}

output "key_vault_key_id" {
  value = azurerm_key_vault_key.key.versionless_id
}
