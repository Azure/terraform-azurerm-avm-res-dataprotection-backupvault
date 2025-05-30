variable "resource_guard_enabled" {
  type        = bool
  default     = false
  description = "Controls whether an Azure Data Protection Resource Guard is deployed to protect the backup vault from accidental or malicious operations."
}

variable "resource_guard_name" {
  type        = string
  default     = null
  description = "The name of the Resource Guard. If not specified, will use the backup vault name with '-guard' suffix."

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
