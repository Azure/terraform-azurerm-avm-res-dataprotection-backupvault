# Backup Instance for Disk
resource "azurerm_data_protection_backup_instance_disk" "disk_backup_instance" {
  count = var.disk_backup_instance_name != null ? 1 : 0

  backup_policy_id             = try(azurerm_data_protection_backup_policy_disk.this[0].id, var.backup_policy_id)
  disk_id                      = var.disk_id
  location                     = var.location
  name                         = var.disk_backup_instance_name
  snapshot_resource_group_name = var.snapshot_resource_group_name
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
      condition     = var.disk_id != null && var.snapshot_resource_group_name != null
      error_message = "Both disk_id and snapshot_resource_group_name must be provided for disk backup."
    }
  }
}

# Backup Policy for Disk
resource "azurerm_data_protection_backup_policy_disk" "this" {
  count = var.disk_backup_instance_name != null ? 1 : 0
  backup_repeating_time_intervals = var.backup_repeating_time_intervals
  default_retention_duration      = var.default_retention_duration
  name                            = var.backup_policy_name != null ? var.backup_policy_name : "${var.name}-disk-policy"
  vault_id                        = azurerm_data_protection_backup_vault.this.id
  time_zone                       = var.time_zone != null ? var.time_zone : "UTC"

  dynamic "retention_rule" {
    for_each = var.retention_rules

    content {
      duration = retention_rule.value.duration != null ? retention_rule.value.duration : "P30D"
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
    create = "30m"
    delete = "30m"
    read   = "5m"
  }

  lifecycle {
    precondition {
      condition     = var.backup_policy_name != null || var.name != null
      error_message = "Either backup_policy_name or name must be provided for the disk backup policy."
    }
  }
}

