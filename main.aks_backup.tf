# AKS/Kubernetes Backup Policies
resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "this" {
  for_each = local.kubernetes_policies

  backup_repeating_time_intervals = each.value.backup_repeating_time_intervals
  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  vault_name                      = azurerm_data_protection_backup_vault.this.name
  time_zone                       = coalesce(each.value.time_zone, "UTC")

  default_retention_rule {
    life_cycle {
      data_store_type = coalesce(each.value.default_retention_life_cycle.data_store_type, "OperationalStore")
      duration        = coalesce(each.value.default_retention_life_cycle.duration, "P14D")
    }
  }
  dynamic "retention_rule" {
    for_each = each.value.retention_rules

    content {
      name     = retention_rule.value.name
      priority = retention_rule.value.priority

      criteria {
        absolute_criteria      = retention_rule.value.criteria[0].absolute_criteria
        days_of_week           = retention_rule.value.criteria[0].days_of_week
        months_of_year         = retention_rule.value.criteria[0].months_of_year
        scheduled_backup_times = retention_rule.value.criteria[0].scheduled_backup_times
        weeks_of_month         = retention_rule.value.criteria[0].weeks_of_month
      }
      life_cycle {
        data_store_type = coalesce(retention_rule.value.life_cycle[0].data_store_type, "OperationalStore")
        duration        = retention_rule.value.life_cycle[0].duration
      }
    }
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }
}

# AKS/Kubernetes Backup Instances
resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "this" {
  for_each = local.kubernetes_instances

  backup_policy_id             = azurerm_data_protection_backup_policy_kubernetes_cluster.this[each.value.backup_policy_key].id
  kubernetes_cluster_id        = each.value.kubernetes_cluster_id
  location                     = var.location
  name                         = each.value.name
  snapshot_resource_group_name = each.value.snapshot_resource_group_name
  vault_id                     = azurerm_data_protection_backup_vault.this.id

  backup_datasource_parameters {
    cluster_scoped_resources_enabled = coalesce(each.value.backup_datasource_parameters.cluster_scoped_resources_enabled, false)
    excluded_namespaces              = coalesce(each.value.backup_datasource_parameters.excluded_namespaces, [])
    excluded_resource_types          = coalesce(each.value.backup_datasource_parameters.excluded_resource_types, [])
    included_namespaces              = coalesce(each.value.backup_datasource_parameters.included_namespaces, [])
    included_resource_types          = coalesce(each.value.backup_datasource_parameters.included_resource_types, [])
    label_selectors                  = coalesce(each.value.backup_datasource_parameters.label_selectors, [])
    volume_snapshot_enabled          = coalesce(each.value.backup_datasource_parameters.volume_snapshot_enabled, false)
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }

  depends_on = [
    azurerm_data_protection_backup_policy_kubernetes_cluster.this,
  ]

  lifecycle {
    precondition {
      condition     = each.value.kubernetes_cluster_id != null
      error_message = "kubernetes_cluster_id must be provided for AKS backup instance '${each.key}'."
    }
  }
}
