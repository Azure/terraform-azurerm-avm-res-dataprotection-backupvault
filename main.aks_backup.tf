# Backup Policy for Kubernetes Cluster
resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "this" {
  count = var.kubernetes_backup_policy_name != null ? 1 : 0

  backup_repeating_time_intervals = var.backup_repeating_time_intervals
  name                            = var.kubernetes_backup_policy_name
  resource_group_name             = var.resource_group_name
  vault_name                      = azurerm_data_protection_backup_vault.this.name
  time_zone                       = var.time_zone

  # Default retention rule is required
  default_retention_rule {
    life_cycle {
      data_store_type = var.default_retention_life_cycle.data_store_type
      duration        = var.default_retention_life_cycle.duration
    }
  }
  # Additional retention rules
  dynamic "retention_rule" {
    for_each = var.kubernetes_retention_rules != null ? var.kubernetes_retention_rules : []

    content {
      name     = retention_rule.value.name
      priority = retention_rule.value.priority

      criteria {
        # Use null for optional values to avoid errors
        absolute_criteria      = try(retention_rule.value.absolute_criteria, null)
        days_of_week           = try(retention_rule.value.days_of_week, null)
        months_of_year         = try(retention_rule.value.months_of_year, null)
        scheduled_backup_times = try(retention_rule.value.scheduled_backup_times, null)
        weeks_of_month         = try(retention_rule.value.weeks_of_month, null)
      }
      life_cycle {
        data_store_type = try(retention_rule.value.data_store_type, "OperationalStore")
        duration        = retention_rule.value.duration
      }
    }
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }
}

# Backup Instance for Kubernetes Cluster
resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "this" {
  count = var.kubernetes_backup_instance_name != null ? 1 : 0

  backup_policy_id = try(
    azurerm_data_protection_backup_policy_kubernetes_cluster.this[0].id,
    var.kubernetes_backup_policy_id
  )
  kubernetes_cluster_id        = var.kubernetes_cluster_id
  location                     = var.location
  name                         = var.kubernetes_backup_instance_name
  snapshot_resource_group_name = var.snapshot_resource_group_name
  vault_id                     = azurerm_data_protection_backup_vault.this.id

  backup_datasource_parameters {
    cluster_scoped_resources_enabled = try(var.backup_datasource_parameters.cluster_scoped_resources_enabled, false)
    excluded_namespaces              = try(var.backup_datasource_parameters.excluded_namespaces, [])
    excluded_resource_types          = try(var.backup_datasource_parameters.excluded_resource_types, [])
    included_namespaces              = try(var.backup_datasource_parameters.included_namespaces, [])
    included_resource_types          = try(var.backup_datasource_parameters.included_resource_types, [])
    label_selectors                  = try(var.backup_datasource_parameters.label_selectors, [])
    volume_snapshot_enabled          = try(var.backup_datasource_parameters.volume_snapshot_enabled, false)
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }

  depends_on = [
    azurerm_data_protection_backup_policy_kubernetes_cluster.this,
    azurerm_role_assignment.this,
  ]
}
