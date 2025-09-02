# Customer Managed Key for encryption of the backup vault
resource "azurerm_data_protection_backup_vault_customer_managed_key" "this" {
  count = var.customer_managed_key != null ? 1 : 0

  data_protection_backup_vault_id = azurerm_data_protection_backup_vault.this.id
  # Compute effective key URL inline without using locals
  key_vault_key_id = coalesce(
    (var.customer_managed_key.key_id != null && var.customer_managed_key.key_id != "" ? var.customer_managed_key.key_id : null),
    (var.customer_managed_key.key_version != null && var.customer_managed_key.key_version != ""
      ? "${var.customer_managed_key.key_vault_key_id}/${var.customer_managed_key.key_version}"
      : var.customer_managed_key.key_vault_key_id
    )
  )

  depends_on = [
    azurerm_data_protection_backup_vault.this
  ]
}
