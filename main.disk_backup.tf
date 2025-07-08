# Disk Backup Policies
resource "azurerm_data_protection_backup_policy_disk" "this" {
  for_each = local.disk_policies

  backup_repeating_time_intervals = each.value.backup_repeating_time_intervals
  default_retention_duration      = each.value.default_retention_duration
  name                            = each.value.name
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  time_zone                       = coalesce(each.value.time_zone, "UTC")

  dynamic "retention_rule" {
    for_each = each.value.retention_rules

    content {
      duration = coalesce(retention_rule.value.duration, "P30D")
      name     = retention_rule.value.name
      priority = retention_rule.value.priority

      dynamic "criteria" {
        for_each = retention_rule.value.criteria

        content {
          absolute_criteria = criteria.value.absolute_criteria
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

# Disk Backup Instances
resource "azurerm_data_protection_backup_instance_disk" "this" {
  for_each = local.disk_instances

  backup_policy_id             = azurerm_data_protection_backup_policy_disk.this[each.value.backup_policy_key].id
  disk_id                      = each.value.disk_id
  location                     = var.location
  name                         = each.value.name
  snapshot_resource_group_name = each.value.snapshot_resource_group_name
  vault_id                     = azurerm_data_protection_backup_vault.this.id

  timeouts {
    create = var.timeout_create
    delete = var.timeout_delete
    read   = var.timeout_read
    update = var.timeout_update
  }

  depends_on = [azurerm_data_protection_backup_policy_disk.this]

  lifecycle {
    precondition {
      condition     = each.value.disk_id != null && each.value.snapshot_resource_group_name != null
      error_message = "Both disk_id and snapshot_resource_group_name must be provided for disk backup instance '${each.key}'."
    }
  }
}

