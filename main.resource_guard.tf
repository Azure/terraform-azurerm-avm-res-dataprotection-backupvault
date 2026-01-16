# Resource Guard for added protection of backup resources
resource "azapi_resource" "resource_guard" {
  count = var.resource_guard_enabled ? 1 : 0

  location  = var.location
  name      = coalesce(var.resource_guard_name, "${var.name}-guard")
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.DataProtection/resourceGuards@2025-07-01"
  body = {
    properties = {
      vaultCriticalOperationExclusionList = var.vault_critical_operation_exclusion_list
    }
  }
  ignore_null_property      = true
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }
}

resource "azapi_resource" "vault_resource_guard_association" {
  count = var.resource_guard_enabled ? 1 : 0

  name      = "DppResourceGuardProxy"
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupResourceGuardProxies@2025-07-01"
  body = {
    properties = {
      resourceGuardResourceId = azapi_resource.resource_guard[0].id
    }
  }
  ignore_null_property      = true
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.resource_guard,
    azapi_resource.backup_vault
  ]
}
