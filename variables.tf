#Unique Module Variables
variable "datastore_type" {
  type        = string
  description = <<DESCRIPTION
Specifies the type of the datastore. Changing this forces a new resource to be created.
Valid options: ArchiveStore, OperationalStore, SnapshotStore, VaultStore.
DESCRIPTION

  validation {
    condition     = contains(["ArchiveStore", "OperationalStore", "SnapshotStore", "VaultStore"], var.datastore_type)
    error_message = "datastore_type must be one of: ArchiveStore, OperationalStore, SnapshotStore, VaultStore."
  }
}

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of this resource. Must be between 5 and 50 characters long."

  validation {
    condition     = length(var.name) >= 5 && length(var.name) <= 50
    error_message = "The name must be between 5 and 50 characters long."
  }
}

variable "redundancy" {
  type        = string
  description = <<DESCRIPTION
Specifies the backup storage redundancy. Changing this forces a new resource to be created.
Valid options: GeoRedundant, LocallyRedundant, ZoneRedundant.
DESCRIPTION

  validation {
    condition     = contains(["GeoRedundant", "LocallyRedundant", "ZoneRedundant"], var.redundancy)
    error_message = "redundancy must be one of: GeoRedundant, LocallyRedundant, ZoneRedundant."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

# Backup policy ID
variable "backup_policy_id" {
  type        = string
  default     = null
  description = "The ID of the Backup Policy that applies to the Backup Instance Blob Storage."
}

variable "backup_policy_name" {
  type        = string
  default     = null
  description = "The name which should be used for this Backup Policy Blob Storage."
}

# Backup Policy Variables for Disk
variable "backup_repeating_time_intervals" {
  type        = list(string)
  default     = []
  description = "Specifies a list of repeating time intervals in ISO 8601 format."
}

# Name for the Backup Instance Blob Storage
variable "blob_backup_instance_name" {
  type        = string
  default     = null
  description = "The name of the Backup Instance Blob Storage."

  validation {
    condition     = var.blob_backup_instance_name != null ? (length(var.blob_backup_instance_name) >= 5 && length(var.blob_backup_instance_name) <= 50) : true
    error_message = "The name must be between 5 and 50 characters long if provided."
  }
}

variable "cross_region_restore_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable cross-region restore for the Backup Vault. Can only be enabled with GeoRedundant redundancy."

  validation {
    condition     = var.redundancy == "GeoRedundant" || var.cross_region_restore_enabled == false
    error_message = "cross_region_restore_enabled can only be enabled when redundancy is set to GeoRedundant."
  }
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION  
}

variable "default_retention_duration" {
  type        = string
  default     = null
  description = "The duration of the default retention rule in ISO 8601 format."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION  
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

# Disk Backup Instance Variables
variable "disk_backup_instance_name" {
  type        = string
  default     = null
  description = "The name of the Backup Instance Disk."

  validation {
    condition     = var.disk_backup_instance_name != null ? (length(var.disk_backup_instance_name) >= 5 && length(var.disk_backup_instance_name) <= 50) : true
    error_message = "The name must be between 5 and 50 characters long if provided."
  }
}

variable "disk_id" {
  type        = string
  default     = null
  description = "The ID of the source Disk for Backup."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "identity_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable Managed Service Identity for the Backup Vault."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "operational_default_retention_duration" {
  type        = string
  default     = null
  description = "The duration of operational default retention rule in ISO 8601 format."
}

variable "postgresql_flexible_backup_instance_name" {
  type        = string
  default     = null
  description = "Name of the PostgreSQL Flexible Backup instance."
}

variable "retention_duration_in_days" {
  type        = number
  default     = 14
  description = <<DESCRIPTION
The soft delete retention duration for this Backup Vault. Valid values are between 14 and 180. Defaults to 14.
DESCRIPTION

  validation {
    condition     = var.retention_duration_in_days >= 14 && var.retention_duration_in_days <= 180
    error_message = "retention_duration_in_days must be between 14 and 180."
  }
}

variable "retention_rules" {
  type = list(object({
    name     = string
    duration = optional(string, null) # Make duration optional to support both cases
    priority = number
    criteria = list(object({
      absolute_criteria      = string
      days_of_month          = optional(list(number), null)
      days_of_week           = optional(list(string), null)
      months_of_year         = optional(list(string), null)
      scheduled_backup_times = optional(list(string), null)
      weeks_of_month         = optional(list(string), null)
    }))
    life_cycle = optional(list(object({
      data_store_type = string
      duration        = string
    })), [])
  }))
  default     = []
  description = "List of retention rules for the backup policy. Optional, can be left as an empty list."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    scope                                  = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "server_id" {
  type        = string
  default     = null
  description = "The ID of the PostgreSQL Flexible Server to be backed up."
}

variable "snapshot_resource_group_name" {
  type        = string
  default     = null
  description = "The name of the Resource Group where snapshots are stored."
}

variable "soft_delete" {
  type        = string
  default     = "On"
  description = <<DESCRIPTION
The state of soft delete for this Backup Vault. Valid options: AlwaysOn, Off, On. Defaults to On.
Once set to AlwaysOn, the setting cannot be changed.
DESCRIPTION

  validation {
    condition     = contains(["AlwaysOn", "Off", "On"], var.soft_delete)
    error_message = "soft_delete must be one of: AlwaysOn, Off, On."
  }
}

# List of container names (optional)
variable "storage_account_container_names" {
  type        = list(string)
  default     = []
  description = "Optional list of container names in the source Storage Account."
}

# Storage account ID
variable "storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the source Storage Account for the Backup Instance."
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "time_zone" {
  type        = string
  default     = null
  description = "Specifies the Time Zone which should be used by the backup schedule."
}

# Timeouts (Optional)
variable "timeout_create" {
  type        = string
  default     = "30m"
  description = "The timeout duration for creating the Backup Instance Blob Storage."
}

variable "timeout_delete" {
  type        = string
  default     = "30m"
  description = "The timeout duration for deleting the Backup Instance Blob Storage."
}

variable "timeout_read" {
  type        = string
  default     = "5m"
  description = "The timeout duration for reading the Backup Instance Blob Storage."
}

variable "timeout_update" {
  type        = string
  default     = "30m"
  description = "The timeout duration for updating the Backup Instance Blob Storage."
}

variable "vault_default_retention_duration" {
  type        = string
  default     = null
  description = "The duration of vault default retention rule in ISO 8601 format."
}
