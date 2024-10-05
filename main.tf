# Required AVM resources interfaces

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_data_protection_backup_vault.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

# Role assignment for the backup vault with managed identity
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id = each.value.principal_id != null ? each.value.principal_id : azurerm_data_protection_backup_vault.this.identity[0].principal_id
  # Use the scope passed in as part of each role assignment
  scope                                  = azurerm_data_protection_backup_vault.this.id
  condition                              = each.value.condition != null ? each.value.condition : null
  condition_version                      = each.value.condition != null ? each.value.condition_version : null
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_data_protection_backup_vault" "this" {
  datastore_type      = var.datastore_type
  location            = var.location
  name                = var.name
  redundancy          = var.redundancy
  resource_group_name = var.resource_group_name
  # Conditionally apply cross_region_restore_enabled only when redundancy is GeoRedundant
  cross_region_restore_enabled = var.redundancy == "GeoRedundant" ? var.cross_region_restore_enabled : null
  retention_duration_in_days   = var.retention_duration_in_days
  soft_delete                  = var.soft_delete
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.identity_enabled ? [1] : []

    content {
      type = "SystemAssigned"
    }
  }
}
