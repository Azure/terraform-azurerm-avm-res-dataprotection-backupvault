# Blob Storage Backup Policies
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
  for_each = local.blob_policies

  name                                   = each.value.name
  vault_id                               = azurerm_data_protection_backup_vault.this.id
  backup_repeating_time_intervals        = length(each.value.backup_repeating_time_intervals) > 0 ? each.value.backup_repeating_time_intervals : null
  operational_default_retention_duration = each.value.operational_default_retention_duration
  time_zone                              = coalesce(each.value.time_zone, "UTC")
  vault_default_retention_duration       = each.value.vault_default_retention_duration

  dynamic "retention_rule" {
    for_each = each.value.retention_rules

    content {
      name     = retention_rule.value.name
      priority = retention_rule.value.priority

      dynamic "criteria" {
        for_each = retention_rule.value.criteria

        content {
          absolute_criteria      = criteria.value.absolute_criteria
          days_of_month          = criteria.value.days_of_month
          days_of_week           = criteria.value.days_of_week
          months_of_year         = criteria.value.months_of_year
          scheduled_backup_times = criteria.value.scheduled_backup_times
          weeks_of_month         = criteria.value.weeks_of_month
        }
      }
      dynamic "life_cycle" {
        for_each = length(retention_rule.value.life_cycle) > 0 ? retention_rule.value.life_cycle : [{
          data_store_type = "VaultStore"
          duration        = retention_rule.value.duration
        }]

        content {
          data_store_type = life_cycle.value.data_store_type
          duration        = life_cycle.value.duration
        }
      }
    }
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }
}

# Blob Storage Backup Instances
resource "azurerm_data_protection_backup_instance_blob_storage" "this" {
  for_each = local.blob_instances

  backup_policy_id                = azurerm_data_protection_backup_policy_blob_storage.this[each.value.backup_policy_key].id
  location                        = var.location
  name                            = each.value.name
  storage_account_id              = each.value.storage_account_id
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  storage_account_container_names = each.value.storage_account_container_names

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }

  depends_on = [
    azurerm_management_lock.this,
    azurerm_data_protection_backup_policy_blob_storage.this
  ]

  lifecycle {
    create_before_destroy = false

    precondition {
      condition     = each.value.storage_account_id != null
      error_message = "storage_account_id must be provided for blob backup instance '${each.key}'."
    }
  }
}
