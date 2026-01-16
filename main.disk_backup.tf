# Disk Backup Policies
resource "azapi_resource" "backup_policy_disk" {
  for_each = local.disk_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = jsonencode({
    properties = {
      policyRules = [{
        name       = "BackupRule"
        objectType = "AzureBackupRule"
        trigger = {
          schedule = {
            repeatingTimeIntervals = each.value.backup_repeating_time_intervals
          }
          timezone = coalesce(each.value.time_zone, "UTC")
        }
        dataStore = {
          dataStoreType = "OperationalStore"
          objectType    = "DataStoreInfoBase"
        }
      }]
      defaultRetentionRule = {
        name       = "Default"
        isDefault  = true
        objectType = "AzureRetentionRule"
        lifeCycle = [{
          dataStoreType = "VaultStore"
          duration      = coalesce(each.value.default_retention_duration, "P30D")
        }]
      }
      retentionRules = [for rr in each.value.retention_rules : {
        name       = rr.name
        priority   = rr.priority
        objectType = "AzureRetentionRule"
        criteria = length(rr.criteria) > 0 ? {
          absoluteCriteria = rr.criteria[0].absolute_criteria
        } : null
        lifeCycle = [{
          dataStoreType = "VaultStore"
          duration      = coalesce(rr.duration, "P30D")
        }]
      }]
      datasourceTypes = ["Microsoft.Compute/disks"]
    }
  })
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }
}

resource "azapi_resource" "backup_instance_disk" {
  for_each = local.disk_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = jsonencode({
    properties = {
      policyId     = azapi_resource.backup_policy_disk[each.value.backup_policy_key].id
      friendlyName = each.value.name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "DatasourceInfo"
        resourceId       = each.value.disk_id
        datasourceType   = "Microsoft.Compute/disks"
        resourceLocation = var.location
      }
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = each.value.disk_id
      }
    }
  })
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }

  lifecycle {
    precondition {
      condition     = each.value.disk_id != null && each.value.snapshot_resource_group_name != null
      error_message = "Both disk_id and snapshot_resource_group_name must be provided for disk backup instance '${each.key}'."
    }
  }
}

