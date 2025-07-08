# PostgreSQL Flexible Server Backup Policies
resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "this" {
  for_each = local.postgresql_flexible_policies

  backup_repeating_time_intervals = each.value.backup_repeating_time_intervals
  name                            = each.value.name
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  time_zone                       = coalesce(each.value.time_zone, "UTC")

  default_retention_rule {
    life_cycle {
      data_store_type = "VaultStore"
      duration        = each.value.default_retention_duration
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
        data_store_type = length(retention_rule.value.life_cycle) > 0 && try(retention_rule.value.life_cycle[0].data_store_type, null) != null ? retention_rule.value.life_cycle[0].data_store_type : "VaultStore"
        duration        = length(retention_rule.value.life_cycle) > 0 && try(retention_rule.value.life_cycle[0].duration, null) != null ? retention_rule.value.life_cycle[0].duration : each.value.default_retention_duration
      }
    }
  }
  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
  }
}

# PostgreSQL Flexible Server Backup Instances
resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "this" {
  for_each = local.postgresql_flexible_instances

  backup_policy_id = azurerm_data_protection_backup_policy_postgresql_flexible_server.this[each.value.backup_policy_key].id
  location         = var.location
  name             = each.value.name
  server_id        = each.value.postgresql_flexible_server_id
  vault_id         = azurerm_data_protection_backup_vault.this.id

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }

  depends_on = [
    azurerm_data_protection_backup_policy_postgresql_flexible_server.this,
  ]

  lifecycle {
    precondition {
      condition     = each.value.postgresql_flexible_server_id != null
      error_message = "postgresql_flexible_server_id must be provided for PostgreSQL Flexible backup instance '${each.key}'."
    }
  }
}
