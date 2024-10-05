# PostgreSQL Flexible Server Backup Policy
resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "postgresql_flexible_backup_policy" {
  count = var.postgresql_flexible_backup_instance_name != null ? 1 : 0

  name                            = var.name
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  backup_repeating_time_intervals = var.backup_repeating_time_intervals
  default_retention_duration      = var.default_retention_duration
  time_zone                       = var.time_zone

  dynamic "retention_rule" {
    for_each = var.retention_rules
    content {
      name     = retention_rule.value.name
      duration = retention_rule.value.duration
      priority = retention_rule.value.priority

      dynamic "criteria" {
        for_each = retention_rule.value.criteria
        content {
          absolute_criteria      = criteria.value.absolute_criteria
          days_of_week           = criteria.value.days_of_week
          months_of_year         = criteria.value.months_of_year
          scheduled_backup_times = criteria.value.scheduled_backup_times
          weeks_of_month         = criteria.value.weeks_of_month
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

# PostgreSQL Flexible Server Backup Instance
resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "postgresql_flexible_backup_instance" {
  count = var.postgresql_flexible_backup_instance_name != null ? 1 : 0

  name             = var.name
  location         = var.location
  vault_id         = azurerm_data_protection_backup_vault.this.id
  server_id        = var.postgresql_flexible_server_id
  backup_policy_id = try(azurerm_data_protection_backup_policy_postgresql_flexible_server.postgresql_flexible_backup_policy[0].id, var.postgresql_flexible_backup_policy_id)

  timeouts {
    create = var.timeout_create
    read   = var.timeout_read
    update = var.timeout_update
    delete = var.timeout_delete
  }
}
