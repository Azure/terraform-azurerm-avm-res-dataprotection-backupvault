# PostgreSQL Flexible Server Backup Policies
resource "azapi_resource" "backup_policy_postgresql_flexible_server" {
  for_each = local.postgresql_flexible_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = {
    properties = {
      objectType      = "BackupPolicy"
      datasourceTypes = ["Microsoft.DBforPostgreSQL/flexibleServers"]
      policyRules = concat(
        # Backup schedule rule
        [{
          name       = "BackupRule"
          objectType = "AzureBackupRule"
          trigger = {
            objectType = "ScheduleBasedTriggerContext"
            schedule = {
              timeZone               = coalesce(each.value.time_zone, "UTC")
              repeatingTimeIntervals = each.value.backup_repeating_time_intervals
            }
            taggingCriteria = concat(
              [for rr in each.value.retention_rules : {
                isDefault       = false
                taggingPriority = rr.priority
                tagInfo = {
                  id      = "${rr.name}_"
                  tagName = rr.name
                }
                criteria = [for c in rr.criteria : {
                  objectType       = "ScheduleBasedBackupCriteria"
                  absoluteCriteria = c.absolute_criteria != null ? [c.absolute_criteria] : null
                  daysOfWeek       = try(c.days_of_week, null)
                  monthsOfYear     = try(c.months_of_year, null)
                  weeksOfMonth     = try(c.weeks_of_month, null)
                }]
              }],
              [{
                isDefault       = true
                taggingPriority = 99
                tagInfo = {
                  id      = "Default_"
                  tagName = "Default"
                }
              }]
            )
          }
          backupParameters = {
            objectType = "AzureBackupParams"
            backupType = "Full"
          }
          dataStore = {
            dataStoreType = "VaultStore"
            objectType    = "DataStoreInfoBase"
          }
        }],
        # Default retention rule
        [{
          name       = "Default"
          objectType = "AzureRetentionRule"
          isDefault  = true
          lifecycles = [{
            sourceDataStore = {
              dataStoreType = "VaultStore"
              objectType    = "DataStoreInfoBase"
            }
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = each.value.default_retention_duration
            }
          }]
        }],
        # Named retention rules
        [for rr in each.value.retention_rules : {
          name       = rr.name
          objectType = "AzureRetentionRule"
          isDefault  = false
          lifecycles = [{
            sourceDataStore = {
              dataStoreType = try(rr.life_cycle[0].data_store_type, "VaultStore")
              objectType    = "DataStoreInfoBase"
            }
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = try(rr.life_cycle[0].duration, rr.duration, each.value.default_retention_duration)
            }
          }]
        }]
      )
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

resource "azapi_resource" "backup_instance_postgresql_flexible_server" {
  for_each = local.postgresql_flexible_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = {
    properties = {
      friendlyName = each.value.name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "DatasourceInfo"
        resourceId       = each.value.postgresql_flexible_server_id
        datasourceType   = "Microsoft.DBforPostgreSQL/flexibleServers"
        resourceLocation = var.location
      }
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = each.value.postgresql_flexible_server_id
      }
      policyInfo = {
        policyId = azapi_resource.backup_policy_postgresql_flexible_server[each.value.backup_policy_key].id
      }
      validationType = "ShallowValidation"
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
      condition     = each.value.postgresql_flexible_server_id != null
      error_message = "postgresql_flexible_server_id must be provided for PostgreSQL Flexible backup instance '${each.key}'."
    }
  }
}
