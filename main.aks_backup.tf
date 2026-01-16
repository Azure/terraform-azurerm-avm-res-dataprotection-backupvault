# AKS/Kubernetes Backup Policies
resource "azapi_resource" "backup_policy_kubernetes_cluster" {
  count = var.kubernetes_backup_policy_name != null ? 1 : 0

  name      = var.kubernetes_backup_policy_name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2025-07-01"
  body = jsonencode({
    properties = {
      policyRules = [{
        name       = "BackupRule"
        objectType = "AzureBackupRule"
        trigger = {
          schedule = {
            repeatingTimeIntervals = var.backup_repeating_time_intervals
          }
          timezone = var.time_zone
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
          dataStoreType = var.default_retention_life_cycle != null ? var.default_retention_life_cycle.data_store_type : "OperationalStore"
          duration      = var.default_retention_life_cycle != null ? var.default_retention_life_cycle.duration : "P14D"
        }]
      }
      retentionRules = [for rr in var.kubernetes_retention_rules : {
        name       = rr.name
        priority   = rr.priority
        objectType = "AzureRetentionRule"
        criteria = {
          absoluteCriteria = try(rr.absolute_criteria, null)
          daysOfWeek       = try(rr.days_of_week, null)
          monthsOfYear     = try(rr.months_of_year, null)
          weeksOfMonth     = try(rr.weeks_of_month, null)
        }
        lifeCycle = [{
          dataStoreType = try(rr.data_store_type, "OperationalStore")
          duration      = rr.duration
        }]
      }]
      datasourceTypes = ["Microsoft.ContainerService/managedClusters"]
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

resource "azapi_resource" "backup_instance_kubernetes_cluster" {
  count = var.kubernetes_backup_instance_name != null ? 1 : 0

  location  = var.location
  name      = var.kubernetes_backup_instance_name
  parent_id = azapi_resource.backup_vault.id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = jsonencode({
    properties = {
      policyId     = length(azapi_resource.backup_policy_kubernetes_cluster) > 0 ? azapi_resource.backup_policy_kubernetes_cluster[0].id : null
      friendlyName = var.kubernetes_backup_instance_name
      objectType   = "BackupInstance"
      dataSourceInfo = {
        objectType       = "DatasourceInfo"
        resourceId       = var.kubernetes_cluster_id
        datasourceType   = "Microsoft.ContainerService/managedClusters"
        resourceLocation = var.location
      }
      datasourceAuthCredentials = null
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = var.kubernetes_cluster_id
      }
      datasourceParameters = {
        objectType                    = "KubernetesClusterBackupDatasourceParameters"
        clusterScopedResourcesEnabled = try(var.backup_datasource_parameters.cluster_scoped_resources_enabled, false)
        excludedNamespaces            = try(var.backup_datasource_parameters.excluded_namespaces, [])
        excludedResourceTypes         = try(var.backup_datasource_parameters.excluded_resource_types, [])
        includedNamespaces            = try(var.backup_datasource_parameters.included_namespaces, [])
        includedResourceTypes         = try(var.backup_datasource_parameters.included_resource_types, [])
        labelSelectors                = try(var.backup_datasource_parameters.label_selectors, [])
        volumeSnapshotEnabled         = try(var.backup_datasource_parameters.volume_snapshot_enabled, false)
        snapshotResourceGroupName     = var.snapshot_resource_group_name
      }
      validationType = "ShallowValidation"
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
  }

  lifecycle {
    precondition {
      condition     = var.kubernetes_cluster_id != null
      error_message = "kubernetes_cluster_id must be provided for direct AKS backup instance."
    }
  }
}
