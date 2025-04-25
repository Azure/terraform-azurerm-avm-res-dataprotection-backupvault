# PostgreSQL Flexible Server Backup Policy
resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "postgresql_flexible_backup_policy" {
  count = var.postgresql_flexible_backup_instance_name != null ? 1 : 0

  backup_repeating_time_intervals = var.backup_repeating_time_intervals
  name                            = var.postgresql_backup_policy_name != null ? var.postgresql_backup_policy_name : "${var.name}-pg-policy"
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  time_zone                       = var.time_zone

  # Required default retention rule
  default_retention_rule {
    life_cycle {
      data_store_type = "VaultStore"
      duration        = var.default_retention_duration
    }
  }
  # Optional additional retention rules
  dynamic "retention_rule" {
    for_each = var.pg_retention_rules

    content {
      name     = retention_rule.value.name
      priority = retention_rule.value.priority

      criteria {
        absolute_criteria      = retention_rule.value.absolute_criteria
        days_of_week           = retention_rule.value.days_of_week
        months_of_year         = retention_rule.value.months_of_year
        scheduled_backup_times = retention_rule.value.scheduled_backup_times
        weeks_of_month         = retention_rule.value.weeks_of_month
      }
      life_cycle {
        data_store_type = retention_rule.value.data_store_type != null ? retention_rule.value.data_store_type : "VaultStore"
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

# PostgreSQL Flexible Server Backup Instance
resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "postgresql_flexible_backup_instance" {
  count = var.postgresql_flexible_backup_instance_name != null ? 1 : 0

  # Change this line to use the variable properly
  backup_policy_id = try(azurerm_data_protection_backup_policy_postgresql_flexible_server.postgresql_flexible_backup_policy[0].id, var.postgresql_flexible_backup_policy_id)
  location         = var.location
  name             = var.postgresql_flexible_backup_instance_name
  server_id        = var.postgresql_flexible_server_id
  vault_id         = azurerm_data_protection_backup_vault.this.id

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }
}
