# AKS/Kubernetes Backup Policies
resource "azapi_resource" "backup_policy_kubernetes_cluster" {
  for_each = local.kubernetes_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = {
    properties = {
      objectType      = "BackupPolicy"
      datasourceTypes = ["Microsoft.ContainerService/managedClusters"]
      policyRules = concat(
        # Backup schedule rule must be listed first per Azure API requirement
        [{
          name       = "BackupRule"
          objectType = "AzureBackupRule"
          trigger = {
            objectType = "ScheduleBasedTriggerContext"
            schedule = {
              timeZone               = each.value.time_zone
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
            backupType = "Incremental"
          }
          dataStore = {
            dataStoreType = "OperationalStore"
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
              dataStoreType = each.value.default_retention_life_cycle != null ? each.value.default_retention_life_cycle.data_store_type : "OperationalStore"
              objectType    = "DataStoreInfoBase"
            }
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = each.value.default_retention_life_cycle != null ? each.value.default_retention_life_cycle.duration : "P14D"
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
              dataStoreType = try(rr.life_cycle[0].data_store_type, "OperationalStore")
              objectType    = "DataStoreInfoBase"
            }
            deleteAfter = {
              objectType = "AbsoluteDeleteOption"
              duration   = try(rr.life_cycle[0].duration, rr.duration, "P30D")
            }
          }]
        }]
      )
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

resource "azapi_resource" "backup_instance_kubernetes_cluster" {
  for_each = local.kubernetes_instances

  location  = var.location
  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = {
    properties = {
      policyInfo = {
        policyId = azapi_resource.backup_policy_kubernetes_cluster[each.value.backup_policy_key].id
      }
      friendlyName = each.value.name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "DatasourceInfo"
        resourceId       = each.value.kubernetes_cluster_id
        datasourceType   = "Microsoft.ContainerService/managedClusters"
        resourceLocation = var.location
      }
      datasourceAuthCredentials = null
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = each.value.kubernetes_cluster_id
      }
      datasourceParameters = {
        objectType                    = "KubernetesClusterBackupDatasourceParameters"
        clusterScopedResourcesEnabled = try(each.value.backup_datasource_parameters.cluster_scoped_resources_enabled, false)
        excludedNamespaces            = try(each.value.backup_datasource_parameters.excluded_namespaces, [])
        excludedResourceTypes         = try(each.value.backup_datasource_parameters.excluded_resource_types, [])
        includedNamespaces            = try(each.value.backup_datasource_parameters.included_namespaces, [])
        includedResourceTypes         = try(each.value.backup_datasource_parameters.included_resource_types, [])
        labelSelectors                = try(each.value.backup_datasource_parameters.label_selectors, [])
        volumeSnapshotEnabled         = try(each.value.backup_datasource_parameters.volume_snapshot_enabled, false)
        snapshotResourceGroupName     = each.value.snapshot_resource_group_name
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
      condition     = each.value.kubernetes_cluster_id != null
      error_message = "kubernetes_cluster_id must be provided for kubernetes backup instance '${each.key}'."
    }
    precondition {
      condition     = each.value.snapshot_resource_group_name != null
      error_message = "snapshot_resource_group_name must be provided for kubernetes backup instance '${each.key}'."
    }
  }
}
