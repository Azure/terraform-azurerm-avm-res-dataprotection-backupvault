# PostgreSQL Backup Policy
resource "azurerm_data_protection_backup_policy_postgresql" "postgresql_backup_policy" {
  count = var.postgresql_backup_instance_name != null ? 1 : 0

  backup_repeating_time_intervals = var.backup_repeating_time_intervals
  default_retention_duration      = var.default_retention_duration
  name                            = var.name
  resource_group_name             = var.resource_group_name
  vault_name                      = azurerm_data_protection_backup_vault.this.name
  time_zone                       = var.time_zone

  dynamic "retention_rule" {
    for_each = var.retention_rules

    content {
      duration = retention_rule.value.duration
      name     = retention_rule.value.name
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
    delete = "30m"
    read   = "5m"
  }
}

# PostgreSQL Backup Instance
resource "azurerm_data_protection_backup_instance_postgresql" "postgresql_backup_instance" {
  count = var.postgresql_backup_instance_name != null ? 1 : 0

  backup_policy_id                        = try(azurerm_data_protection_backup_policy_postgresql.postgresql_backup_policy[0].id, var.postgresql_backup_policy_id)
  database_id                             = var.postgresql_database_id
  location                                = var.location
  name                                    = var.name
  vault_id                                = azurerm_data_protection_backup_vault.this.id
  database_credential_key_vault_secret_id = var.postgresql_key_vault_secret_id

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }
}
