# Locals for organizing backup policies and instances by type
locals {
  # Validation: ensure all backup instances reference existing backup policies
  backup_instances_validation = {
    for instance_key, instance in var.backup_instances :
    instance_key => {
      policy_exists = contains(keys(var.backup_policies), instance.backup_policy_key)
      policy_type_matches = (
        contains(keys(var.backup_policies), instance.backup_policy_key) ?
        var.backup_policies[instance.backup_policy_key].type == instance.type :
        false
      )
    }
  }
  blob_instances = { for k, v in var.backup_instances : k => v if v.type == "blob" }
  blob_policies  = { for k, v in var.backup_policies : k => v if v.type == "blob" }
  # Organize backup instances by type
  disk_instances = { for k, v in var.backup_instances : k => v if v.type == "disk" }
  # Organize backup policies by type
  disk_policies                      = { for k, v in var.backup_policies : k => v if v.type == "disk" }
  kubernetes_instances               = { for k, v in var.backup_instances : k => v if v.type == "kubernetes" }
  kubernetes_policies                = { for k, v in var.backup_policies : k => v if v.type == "kubernetes" }
  postgresql_flexible_instances      = { for k, v in var.backup_instances : k => v if v.type == "postgresql_flexible" }
  postgresql_flexible_policies       = { for k, v in var.backup_policies : k => v if v.type == "postgresql_flexible" }
  postgresql_instances               = { for k, v in var.backup_instances : k => v if v.type == "postgresql" }
  postgresql_policies                = { for k, v in var.backup_policies : k => v if v.type == "postgresql" }
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"
  # Check for any validation errors
  validation_errors = [
    for instance_key, validation in local.backup_instances_validation :
    instance_key if !validation.policy_exists || !validation.policy_type_matches
  ]
}
