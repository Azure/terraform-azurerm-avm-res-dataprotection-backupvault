# AKS/Kubernetes Backup Policies
resource "azapi_resource" "backup_policy_kubernetes_cluster" {
  for_each = local.kubernetes_policies

  name      = each.value.name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = {
    properties = {
      objectType = "BackupPolicy"
      policyRules = [{
        name       = "BackupRule"
        objectType = "AzureBackupRule"
        trigger = {
          objectType = "ScheduleBasedTriggerContext"
          schedule = {
            repeatingTimeIntervals = each.value.backup_repeating_time_intervals
          }
          taggingCriteria = concat([
            {
              isDefault       = true
              taggingPriority = 999
              tagInfo = {
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
            }
          ])
          timezone = each.value.time_zone
        }
        backupParameters = {
          objectType = "AzureBackupParams"
          backupType = "Snapshot"
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
          dataStoreType = each.value.default_retention_life_cycle != null ? each.value.default_retention_life_cycle.data_store_type : "OperationalStore"
          duration      = each.value.default_retention_life_cycle != null ? each.value.default_retention_life_cycle.duration : "P14D"
        }]
      }
      retentionRules = [for rr in each.value.retention_rules : {
        name       = rr.name
        priority   = rr.priority
        objectType = "AzureRetentionRule"
        criteria = {
          absoluteCriteria = try(rr.criteria[0].absolute_criteria, null)
          daysOfWeek       = try(rr.criteria[0].days_of_week, null)
          monthsOfYear     = try(rr.criteria[0].months_of_year, null)
          weeksOfMonth     = try(rr.criteria[0].weeks_of_month, null)
        }
        lifeCycle = [{
          dataStoreType = try(rr.life_cycle[0].data_store_type, "OperationalStore")
          duration      = try(rr.life_cycle[0].duration, rr.duration, "P30D")
        }]
      }]
      datasourceTypes = ["Microsoft.ContainerService/managedClusters"]
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
      policyId     = azapi_resource.backup_policy_kubernetes_cluster[each.value.backup_policy_key].id
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
