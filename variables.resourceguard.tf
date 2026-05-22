variable "resource_guard_enabled" {
  type        = bool
  default     = false
  description = "Controls whether a Resource Guard is associated with the backup vault. When true and `resource_guard_resource_id` is null, a new Resource Guard is created in the same resource group. When true and `resource_guard_resource_id` is provided, the existing external guard is associated instead."
}

variable "resource_guard_name" {
  type        = string
  default     = null
  description = "The name of the Resource Guard. If not specified, will use the backup vault name with '-guard' suffix. Only used when creating a new resource guard (i.e., when `resource_guard_resource_id` is null)."

  validation {
    condition = (
      var.resource_guard_name == null ||
      (
        can(length(var.resource_guard_name)) &&
        can(regex("^.{3,63}$", var.resource_guard_name))
      )
    )
    error_message = "If provided, resource_guard_name must be between 3 and 63 characters long."
  }
}

variable "resource_guard_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of an existing Resource Guard to associate with the backup vault. When provided (with `resource_guard_enabled = true`), no new guard is created — the existing one is used directly."

  validation {
    condition = (
      var.resource_guard_resource_id == null ||
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.DataProtection/resourceGuards/[^/]+$", var.resource_guard_resource_id))
    )
    error_message = "If provided, resource_guard_resource_id must be a valid Azure resource ID for a Microsoft.DataProtection/resourceGuards resource."
  }
}

variable "vault_critical_operation_exclusion_list" {
  type        = list(string)
  default     = []
  description = <<DESCRIPTION
A list of the critical operations which are not protected by Resource Guard.
By default, all critical operations are protected. Only exclude operations that you want to allow without additional protection.
Possible values include: "Delete", "Update", "DisableSoftDelete", and "ChangeBackupProperties".
DESCRIPTION

  validation {
    condition     = alltrue([for op in var.vault_critical_operation_exclusion_list : contains(["Delete", "Update", "DisableSoftDelete", "ChangeBackupProperties"], op)])
    error_message = "Valid values for vault_critical_operation_exclusion_list are: 'Delete', 'Update', 'DisableSoftDelete', and 'ChangeBackupProperties'."
  }
}
