resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "this" {
  for_each = var.policies

  backup_repeating_time_intervals = each.value.backup_repeating_time_intervals
  name                            = each.value.name
  vault_id                        = var.vault_id
  time_zone                       = each.value.time_zone

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
        absolute_criteria      = try(retention_rule.value.criteria[0].absolute_criteria, null)
        days_of_week           = try(retention_rule.value.criteria[0].days_of_week, null) != null ? toset(retention_rule.value.criteria[0].days_of_week) : null
        months_of_year         = try(retention_rule.value.criteria[0].months_of_year, null) != null ? toset(retention_rule.value.criteria[0].months_of_year) : null
        scheduled_backup_times = try(retention_rule.value.criteria[0].scheduled_backup_times, null) != null ? toset(retention_rule.value.criteria[0].scheduled_backup_times) : null
        weeks_of_month         = try(retention_rule.value.criteria[0].weeks_of_month, null) != null ? toset(retention_rule.value.criteria[0].weeks_of_month) : null
      }
      dynamic "life_cycle" {
        for_each = length(try(retention_rule.value.life_cycle, [])) > 0 ? retention_rule.value.life_cycle : [{
          data_store_type = "VaultStore"
          duration        = each.value.default_retention_duration
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

  lifecycle {
    precondition {
      condition     = length(each.value.backup_repeating_time_intervals) > 0
      error_message = "backup_repeating_time_intervals must contain at least one interval for PostgreSQL Flexible policy '${each.key}'."
    }
  }
}

resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "this" {
  for_each = var.instances

  backup_policy_id = azurerm_data_protection_backup_policy_postgresql_flexible_server.this[each.value.backup_policy_key].id
  location         = var.location
  name             = each.value.name
  server_id        = each.value.postgresql_flexible_server_id
  vault_id         = var.vault_id

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }

  lifecycle {
    precondition {
      condition     = each.value.postgresql_flexible_server_id != null
      error_message = "postgresql_flexible_server_id must be provided for PostgreSQL Flexible backup instance '${each.key}'."
    }
    precondition {
      condition     = contains(keys(var.policies), each.value.backup_policy_key)
      error_message = "backup_policy_key '${each.value.backup_policy_key}' for instance '${each.key}' must reference an existing PostgreSQL Flexible policy key."
    }
  }
}
