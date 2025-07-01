# Locals for organizing backup policies and instances by type
locals {
  # Validation: ensure all backup instances reference existing backup policies
  # Locals required for resource for_each usage
  blob_instances                     = { for k, v in var.backup_instances : k => v if v.type == "blob" }
  blob_policies                      = { for k, v in var.backup_policies : k => v if v.type == "blob" }
  disk_instances                     = { for k, v in var.backup_instances : k => v if v.type == "disk" }
  disk_policies                      = { for k, v in var.backup_policies : k => v if v.type == "disk" }
  postgresql_flexible_instances      = { for k, v in var.backup_instances : k => v if v.type == "postgresql_flexible" }
  postgresql_flexible_policies       = { for k, v in var.backup_policies : k => v if v.type == "postgresql_flexible" }
  postgresql_instances               = { for k, v in var.backup_instances : k => v if v.type == "postgresql" }
  postgresql_policies                = { for k, v in var.backup_policies : k => v if v.type == "postgresql" }
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
}
