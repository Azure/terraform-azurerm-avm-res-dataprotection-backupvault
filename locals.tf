# Locals for organizing backup policies and instances by type
locals {
  # Validation: ensure all backup instances reference existing backup policies
  blob_instances = { for k, v in var.backup_instances : k => v if v.type == "blob" }
  blob_policies  = { for k, v in var.backup_policies : k => v if v.type == "blob" }
  # Organize backup instances by type
  disk_instances = { for k, v in var.backup_instances : k => v if v.type == "disk" }
  # Organize backup policies by type
  disk_policies                      = { for k, v in var.backup_policies : k => v if v.type == "disk" }
  postgresql_flexible_instances      = { for k, v in var.backup_instances : k => v if v.type == "postgresql_flexible" }
  postgresql_flexible_policies       = { for k, v in var.backup_policies : k => v if v.type == "postgresql_flexible" }
  postgresql_instances               = { for k, v in var.backup_instances : k => v if v.type == "postgresql" }
  postgresql_policies                = { for k, v in var.backup_policies : k => v if v.type == "postgresql" }
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
}
