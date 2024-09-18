# Backup Instance for Disk
resource "azurerm_data_protection_backup_instance_disk" "disk_backup_instance" {
  count = var.disk_backup_instance_name != null ? 1 : 0

  name                         = var.disk_backup_instance_name
  location                     = var.location
  vault_id                     = azurerm_data_protection_backup_vault.this.id
  disk_id                      = var.disk_id
  snapshot_resource_group_name = var.snapshot_resource_group_name
  backup_policy_id             = length(azurerm_data_protection_backup_policy_disk.this) > 0 ? azurerm_data_protection_backup_policy_disk.this[count.index].id : null

  timeouts {
    create = var.timeout_create
    read   = var.timeout_read
    update = var.timeout_update
    delete = var.timeout_delete
  }
}

# Backup Policy for Disk
resource "azurerm_data_protection_backup_policy_disk" "this" {
  count = var.disk_backup_instance_name != null ? 1 : 0

  name                          = var.backup_policy_name
  vault_id                      = azurerm_data_protection_backup_vault.this.id
  backup_repeating_time_intervals = var.backup_repeating_time_intervals
  default_retention_duration     = var.default_retention_duration != null ? var.default_retention_duration : "P30D"
  time_zone                      = var.time_zone

  # Retention rules block (optional)
  dynamic "retention_rule" {
    for_each = var.retention_rules
    content {
      name     = retention_rule.value.name
      duration = retention_rule.value.duration
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
    read   = "5m"
    delete = "30m"
  }
}

