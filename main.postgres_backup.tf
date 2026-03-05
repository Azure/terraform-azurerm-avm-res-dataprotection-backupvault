# PostgreSQL Backup Policies
resource "azapi_resource" "backup_policy_postgresql" {
  for_each = local.postgresql_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-09-01"
  body = {
    properties = {
      objectType      = "BackupPolicy"
      datasourceTypes = ["Microsoft.DBforPostgreSQL/servers/databases"]
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
              duration   = coalesce(each.value.default_retention_duration, "P30D")
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
              dataStoreType = "VaultStore"
              objectType    = "DataStoreInfoBase"
            }
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = coalesce(each.value.default_retention_duration, "P30D")
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

resource "azapi_resource" "backup_instance_postgresql" {
  for_each = local.postgresql_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-09-01"
  body = {
    properties = {
      policyId     = azapi_resource.backup_policy_postgresql[each.value.backup_policy_key].id
      friendlyName = each.value.name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "DatasourceInfo"
        resourceId       = each.value.postgresql_database_id
        datasourceType   = "Microsoft.DBforPostgreSQL/servers/databases"
        resourceLocation = var.location
      }
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = each.value.postgresql_database_id
      }
      datasourceAuthCredentials = {
        objectType            = "SecretStoreBasedAuthCredentials"
        secretStoreType       = "AzureKeyVault"
        secretStoreUri        = each.value.postgresql_key_vault_secret_id
        secretStoreResourceId = join("/", slice(split(each.value.postgresql_key_vault_secret_id, "/"), 0, 9))
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

  lifecycle {
    ignore_changes = [
      body.properties.dataSourceInfo.objectType,
      body.properties.dataSourceSetInfo.objectType
    ]

    precondition {
      condition     = each.value.postgresql_database_id != null && each.value.postgresql_key_vault_secret_id != null
      error_message = "Both postgresql_database_id and postgresql_key_vault_secret_id must be provided for PostgreSQL backup instance '${each.key}'."
    }
  }
}
