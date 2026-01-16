# PostgreSQL Backup Policies
resource "azapi_resource" "backup_policy_postgresql" {
  for_each = local.postgresql_policies

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
          dataStoreType = "VaultStore"
          duration      = coalesce(each.value.default_retention_duration, "P30D")
        }]
      }
      retentionRules = [for rr in each.value.retention_rules : {
        name       = rr.name
        priority   = rr.priority
        objectType = "AzureRetentionRule"
        criteria = {
          absoluteCriteria     = rr.criteria[0].absolute_criteria
          daysOfWeek           = rr.criteria[0].days_of_week
          monthsOfYear         = rr.criteria[0].months_of_year
          scheduledBackupTimes = rr.criteria[0].scheduled_backup_times
          weeksOfMonth         = rr.criteria[0].weeks_of_month
        }
      }]
      datasourceTypes = ["Microsoft.DBforPostgreSQL/servers/databases"]
    }
  }
  ignore_null_property      = true
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

resource "azapi_resource" "backup_instance_postgresql" {
  for_each = local.postgresql_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
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
  ignore_null_property      = true
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    precondition {
      condition     = each.value.postgresql_database_id != null && each.value.postgresql_key_vault_secret_id != null
      error_message = "Both postgresql_database_id and postgresql_key_vault_secret_id must be provided for PostgreSQL backup instance '${each.key}'."
    }
  }
}
