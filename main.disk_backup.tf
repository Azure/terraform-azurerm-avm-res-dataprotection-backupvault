# Disk Backup Policies
resource "azapi_resource" "backup_policy_disk" {
  for_each = local.disk_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = {
    properties = {
      objectType = "BackupPolicy"
      policyRules = [
        {
          name       = "BackupRule"
          objectType = "AzureBackupRule"
          trigger = {
            objectType = "ScheduleBasedTriggerContext"
            schedule = {
              repeatingTimeIntervals = each.value.backup_repeating_time_intervals
            }
            taggingCriteria = [
              {
                isDefault       = true
                taggingPriority = 99
                tagInfo = {
                  id      = "Default_"
                  tagName = "Default"
                }
              }
            ]
            timezone = coalesce(each.value.time_zone, "UTC")
          }
          backupParameters = {
            objectType = "AzureBackupParams"
            backupType = "Incremental"
          }
          dataStore = {
            dataStoreType = "OperationalStore"
            objectType    = "DataStoreInfoBase"
          }
        },
        {
          name       = "Default"
          isDefault  = true
          objectType = "AzureRetentionRule"
          lifecycles = [{
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = coalesce(each.value.default_retention_duration, "P30D")
            }
            sourceDataStore = {
              dataStoreType = "OperationalStore"
              objectType    = "DataStoreInfoBase"
            }
          }]
        }
      ]
      datasourceTypes = ["Microsoft.Compute/disks"]
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

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
  body = {
    properties = {
      objectType   = "BackupInstance"
      friendlyName = each.value.name
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
      datasourceParameters = {
        objectType                = "AzureBackupParams"
        snapshotResourceGroupName = each.value.snapshot_resource_group_name
      }
      policyInfo = {
        policyId = azapi_resource.backup_policy_disk[each.value.backup_policy_key].id
      }
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

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }

  lifecycle {
    ignore_changes = [
      body.properties.dataSourceInfo.objectType,
      body.properties.dataSourceSetInfo.objectType
    ]

    precondition {
      condition     = each.value.disk_id != null && each.value.snapshot_resource_group_name != null
      error_message = "Both disk_id and snapshot_resource_group_name must be provided for disk backup instance '${each.key}'."
    }
  }
}

resource "time_sleep" "wait_for_backup_instance_disk" {
  for_each = azapi_resource.backup_instance_disk

  create_duration = var.wait_for_backup_instance_configure_duration

  depends_on = [azapi_resource.backup_instance_disk]
}

