# Blob Storage Backup Policies
resource "azapi_resource" "backup_policy_blob_storage" {
  for_each = local.blob_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = {
    properties = {
      objectType = "BackupPolicy"
      policyRules = concat(
        # Default Retention Rule (VaultStore)
        [{
          name       = "Default"
          isDefault  = true
          objectType = "AzureRetentionRule"
          lifecycles = [{
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = coalesce(each.value.vault_default_retention_duration, "P30D")
            }
            sourceDataStore = {
              dataStoreType = "VaultStore"
              objectType    = "DataStoreInfoBase"
            }
            targetDataStoreCopySettings = []
          }]
        }],
        # Additional Retention Rules
        [for rr in each.value.retention_rules : {
          name       = rr.name
          isDefault  = false
          objectType = "AzureRetentionRule"
          lifecycles = length(rr.life_cycle) > 0 ? [for lc in rr.life_cycle : {
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = lc.duration
            }
            sourceDataStore = {
              dataStoreType = lc.data_store_type
              objectType    = "DataStoreInfoBase"
            }
            targetDataStoreCopySettings = []
            }] : [{
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = rr.duration
            }
            sourceDataStore = {
              dataStoreType = "VaultStore"
              objectType    = "DataStoreInfoBase"
            }
            targetDataStoreCopySettings = []
          }]
        }],
        # Backup Rule
        [{
          name       = "BackupDaily"
          objectType = "AzureBackupRule"
          backupParameters = {
            objectType = "AzureBackupParams"
            backupType = "Discrete"
          }
          dataStore = {
            dataStoreType = "VaultStore"
            objectType    = "DataStoreInfoBase"
          }
          trigger = {
            objectType = "ScheduleBasedTriggerContext"
            schedule = {
              timeZone               = coalesce(each.value.time_zone, "UTC")
              repeatingTimeIntervals = each.value.backup_repeating_time_intervals
            }
            taggingCriteria = concat([
              {
                isDefault       = true
                taggingPriority = 99
                tagInfo = {
                  id      = "Default_"
                  tagName = "Default"
                }
              }
              ], [
              for rr in each.value.retention_rules : {
                isDefault       = false
                taggingPriority = rr.priority
                tagInfo = {
                  tagName = rr.name
                }
                criteria = length(rr.criteria) > 0 ? [for c in rr.criteria : {
                  objectType       = "ScheduleBasedBackupCriteria"
                  absoluteCriteria = c.absolute_criteria != null ? [c.absolute_criteria] : null
                  daysOfTheWeek    = c.days_of_week
                  daysOfMonth      = c.days_of_month != null ? [for d in c.days_of_month : { date = d, isLast = false }] : null
                  monthsOfYear     = c.months_of_year
                  scheduleTimes    = c.scheduled_backup_times
                  weeksOfTheMonth  = c.weeks_of_month
                }] : null
              }
            ])
          }
        }]
      )
      datasourceTypes = ["Microsoft.Storage/storageAccounts/blobServices"]
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
}

resource "azapi_resource" "backup_instance_blob_storage" {
  for_each = local.blob_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = {
    properties = {
      friendlyName = each.value.name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "Datasource"
        resourceID       = each.value.storage_account_id
        datasourceType   = "Microsoft.Storage/storageAccounts/blobServices"
        resourceLocation = var.location
      }
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = each.value.storage_account_id
      }
      policyInfo = {
        policyId = azapi_resource.backup_policy_blob_storage[each.value.backup_policy_key].id
        policyParameters = {
          dataStoreParametersList = []
          backupDatasourceParametersList = [{
            objectType     = "BlobBackupDatasourceParameters"
            containersList = each.value.storage_account_container_names
          }]
        }
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
    create_before_destroy = false
    ignore_changes = [
      body.properties.dataSourceInfo.objectType,
      body.properties.dataSourceSetInfo.objectType
    ]

    precondition {
      condition     = each.value.storage_account_id != null
      error_message = "storage_account_id must be provided for blob backup instance '${each.key}'."
    }
  }
}
