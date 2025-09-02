# Customer Managed Key for encryption of the backup vault
resource "azurerm_data_protection_backup_vault_customer_managed_key" "this" {
  count = var.customer_managed_key != null ? 1 : 0

  data_protection_backup_vault_id = azurerm_data_protection_backup_vault.this.id
  # Build key URL from AVM interface fields, keep conditional on a single line to avoid parsing issues.
  key_vault_key_id = var.customer_managed_key.key_version != null && var.customer_managed_key.key_version != "" ? format("https://%s.vault.azure.net/keys/%s/%s", element(split("/vaults/", var.customer_managed_key.key_vault_resource_id), 1), var.customer_managed_key.key_name, var.customer_managed_key.key_version) : format("https://%s.vault.azure.net/keys/%s", element(split("/vaults/", var.customer_managed_key.key_vault_resource_id), 1), var.customer_managed_key.key_name)

  depends_on = [
    azurerm_data_protection_backup_vault.this
  ]
}
