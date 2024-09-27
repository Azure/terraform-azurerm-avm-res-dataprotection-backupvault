# Backup Instance for Blob Storage
resource "azurerm_data_protection_backup_instance_blob_storage" "blob_backup_instance" {
  count = var.blob_backup_instance_name != null ? 1 : 0

  name               = var.blob_backup_instance_name
  location           = var.location
  vault_id           = azurerm_data_protection_backup_vault.this.id
  storage_account_id = var.storage_account_id
  backup_policy_id   = try(azurerm_data_protection_backup_policy_blob_storage.this[0].id, null)  # Use try to handle the case when it doesn't exist

  storage_account_container_names = var.storage_account_container_names

  depends_on = [
    azurerm_role_assignment.this,
    azurerm_data_protection_backup_policy_blob_storage.this
  ]

  timeouts {
    create = var.timeout_create
    read   = var.timeout_read
    update = var.timeout_update
    delete = var.timeout_delete
  }
}



# Backup Policy for Blob Storage
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
count = var.blob_backup_instance_name != null ? 1 : 0

  name                                   = var.backup_policy_name
  vault_id                               = azurerm_data_protection_backup_vault.this.id
  operational_default_retention_duration = var.operational_default_retention_duration
  vault_default_retention_duration       = var.vault_default_retention_duration
  backup_repeating_time_intervals        = var.backup_repeating_time_intervals
  time_zone                              = var.time_zone

  # Retention rules block (optional)
  dynamic "retention_rule" {
    for_each = var.retention_rules
    content {
      name     = retention_rule.value.name
      priority = retention_rule.value.priority
      # duration = retention_rule.value.duration

      # Criteria block inside retention_rule
      dynamic "criteria" {
        for_each = retention_rule.value.criteria
        content {
          absolute_criteria     = criteria.value.absolute_criteria
          days_of_month         = criteria.value.days_of_month
          days_of_week          = criteria.value.days_of_week
          months_of_year        = criteria.value.months_of_year
          scheduled_backup_times = criteria.value.scheduled_backup_times
          weeks_of_month        = criteria.value.weeks_of_month
        }
      }

      # Life cycle block inside retention_rule
      dynamic "life_cycle" {
        for_each = retention_rule.value.life_cycle
        content {
          data_store_type = life_cycle.value.data_store_type
          duration        = life_cycle.value.duration
        }
      }
    }
  }

  timeouts {
    create = "30m"
    read   = "5m"
    delete = "30m"
  }
}
