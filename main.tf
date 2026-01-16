# Required AVM resources interfaces
data "azapi_client_config" "current" {}

data "azurerm_role_definition" "role_defs" {
  for_each = { for k, v in var.role_assignments : k => v if !strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring)) }

  name = each.value.role_definition_id_or_name
}

resource "azapi_resource" "backup_vault" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.DataProtection/backupVaults@2025-07-01"
  body = {
    properties = {
      storageSettings = [{
        datastoreType = var.datastore_type
        type          = var.redundancy
      }]
      securitySettings = {
        softDeleteSettings = {
          state                   = var.soft_delete
          retentionDurationInDays = var.retention_duration_in_days
        }
        immutabilitySettings = {
          state = var.immutability
        }
        crossRegionRestoreSettings = var.redundancy == "GeoRedundant" ? {
          state = var.cross_region_restore_enabled ? "Enabled" : "Disabled"
        } : null
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = (var.managed_identities.system_assigned || length(try(var.managed_identities.user_assigned_resource_ids, [])) > 0) ? [1] : []

    content {
      type         = var.managed_identities.system_assigned && length(try(var.managed_identities.user_assigned_resource_ids, [])) > 0 ? "SystemAssigned,UserAssigned" : var.managed_identities.system_assigned ? "SystemAssigned" : "UserAssigned"
      identity_ids = try(var.managed_identities.user_assigned_resource_ids, [])
    }
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = var.lock.kind
      notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name      = uuidv5("6ba7b810-9dad-11d1-80b4-00c04fd430c8", "${coalesce(each.value.scope, azapi_resource.backup_vault.id)}-${each.value.principal_id}-${strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : data.azurerm_role_definition.role_defs[each.key].role_definition_id}")
  parent_id = coalesce(each.value.scope, azapi_resource.backup_vault.id)
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      roleDefinitionId                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : data.azurerm_role_definition.role_defs[each.key].role_definition_id
      principalId                        = each.value.principal_id == "system-assigned" ? try(azapi_resource.backup_vault.identity[0].principal_id, null) : each.value.principal_id
      principalType                      = each.value.principal_type
      scope                              = coalesce(each.value.scope, azapi_resource.backup_vault.id)
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = coalesce(each.value.name, "diag-${var.name}")
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  body = {
    properties = {
      workspaceId                 = each.value.workspace_resource_id
      storageAccountId            = each.value.storage_account_resource_id
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      marketplacePartnerId        = each.value.marketplace_partner_resource_id
      logs = concat(
        [for c in each.value.log_categories : { category = c }],
        [for g in each.value.log_groups : { categoryGroup = g }]
      )
      metrics = [for m in each.value.metric_categories : { category = m, enabled = true }]
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_casing             = true
  ignore_missing_property   = true
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

  lifecycle {
    ignore_changes = [
      body.properties.logs,
      output
    ]
  }
}
