# PostgreSQL Backup Policies
resource "azurerm_data_protection_backup_policy_postgresql" "this" {
  for_each = local.postgresql_policies

  backup_repeating_time_intervals = each.value.backup_repeating_time_intervals
  default_retention_duration      = each.value.default_retention_duration
  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  vault_name                      = azurerm_data_protection_backup_vault.this.name
  time_zone                       = coalesce(each.value.time_zone, "UTC")

  dynamic "retention_rule" {
    for_each = each.value.retention_rules

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
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }
}

# PostgreSQL Backup Instances
resource "azurerm_data_protection_backup_instance_postgresql" "this" {
  for_each = local.postgresql_instances

  backup_policy_id                        = azurerm_data_protection_backup_policy_postgresql.this[each.value.backup_policy_key].id
  database_id                             = each.value.postgresql_database_id
  location                                = var.location
  name                                    = each.value.name
  vault_id                                = azurerm_data_protection_backup_vault.this.id
  database_credential_key_vault_secret_id = each.value.postgresql_key_vault_secret_id

  depends_on = [azurerm_data_protection_backup_policy_postgresql.this]

  lifecycle {
    precondition {
      condition     = each.value.postgresql_database_id != null && each.value.postgresql_key_vault_secret_id != null
      error_message = "Both postgresql_database_id and postgresql_key_vault_secret_id must be provided for PostgreSQL backup instance '${each.key}'."
    }
  }
}
