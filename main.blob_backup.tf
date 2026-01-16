# Blob Storage Backup Policies
resource "azapi_resource" "backup_policy_blob_storage" {
  for_each = local.blob_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = {
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
          dataStoreType = "OperationalStore"
          duration      = coalesce(each.value.operational_default_retention_duration, "P7D")
          }, {
          dataStoreType = "VaultStore"
          duration      = coalesce(each.value.vault_default_retention_duration, "P30D")
        }]
      }
      retentionRules = [for rr in each.value.retention_rules : {
        name       = rr.name
        priority   = rr.priority
        objectType = "AzureRetentionRule"
        criteria = length(rr.criteria) > 0 ? {
          absoluteCriteria     = rr.criteria[0].absolute_criteria
          daysOfMonth          = rr.criteria[0].days_of_month
          daysOfWeek           = rr.criteria[0].days_of_week
          monthsOfYear         = rr.criteria[0].months_of_year
          scheduledBackupTimes = rr.criteria[0].scheduled_backup_times
          weeksOfMonth         = rr.criteria[0].weeks_of_month
        } : null
        lifeCycle = length(rr.life_cycle) > 0 ? [for lc in rr.life_cycle : {
          dataStoreType = lc.data_store_type
          duration      = lc.duration
          }] : [{
          dataStoreType = "VaultStore"
          duration      = rr.duration
        }]
      }]
      datasourceTypes = ["Microsoft.Storage/storageAccounts/blobServices"]
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property      = true
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

resource "azapi_resource" "backup_instance_blob_storage" {
  for_each = local.blob_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = {
    properties = {
      policyId     = azapi_resource.backup_policy_blob_storage[each.value.backup_policy_key].id
      friendlyName = each.value.name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "DatasourceInfo"
        resourceId       = each.value.storage_account_id
        datasourceType   = "Microsoft.Storage/storageAccounts/blobServices"
        resourceLocation = var.location
      }
      datasourceAuthCredentials = null
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = each.value.storage_account_id
      }
      policyInfo     = null
      validationType = "ShallowValidation"
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property      = true
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
    create_before_destroy = false

    precondition {
      condition     = each.value.storage_account_id != null
      error_message = "storage_account_id must be provided for blob backup instance '${each.key}'."
    }
  }
}
