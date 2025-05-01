# Resource Guard for added protection of backup resources
resource "azurerm_data_protection_resource_guard" "this" {
  count = var.resource_guard_enabled ? 1 : 0

  location            = var.location
  name                = coalesce(var.resource_guard_name, "${var.name}-guard")
  resource_group_name = var.resource_group_name
  # Add standard tags plus any custom tags
  tags = var.tags
  # Optional list of operations to exclude from protection
  vault_critical_operation_exclusion_list = var.vault_critical_operation_exclusion_list

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }
}

# Associate Resource Guard with Backup Vault using azapi_resource
resource "azapi_resource" "vault_resource_guard_association" {
  count = var.resource_guard_enabled ? 1 : 0

  type = "Microsoft.DataProtection/backupVaults/backupResourceGuardProxies@2023-05-01"
  body = jsonencode({
    properties = {
      resourceGuardResourceId = azurerm_data_protection_resource_guard.this[0].id
    }
  })
  name                      = "DppResourceGuardProxy"
  parent_id                 = azurerm_data_protection_backup_vault.this.id
  schema_validation_enabled = false

  depends_on = [
    azurerm_data_protection_resource_guard.this,
    azurerm_data_protection_backup_vault.this
  ]
}
