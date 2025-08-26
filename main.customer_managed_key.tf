# Customer Managed Key for encryption of the backup vault
resource "azurerm_data_protection_backup_vault_customer_managed_key" "this" {
  count = var.customer_managed_key != null ? 1 : 0

  data_protection_backup_vault_id = azurerm_data_protection_backup_vault.this.id
  key_vault_key_id                = var.customer_managed_key.key_version != null ? "${var.customer_managed_key.key_vault_resource_id}/keys/${var.customer_managed_key.key_name}/${var.customer_managed_key.key_version}" : "${var.customer_managed_key.key_vault_resource_id}/keys/${var.customer_managed_key.key_name}"

  depends_on = [
    azurerm_data_protection_backup_vault.this
  ]
}