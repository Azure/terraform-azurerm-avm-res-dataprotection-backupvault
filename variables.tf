# Direct AKS/Kubernetes backup configuration variables

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

# Direct AKS/Kubernetes backup configuration variables
variable "backup_datasource_parameters" {
  type = object({
    excluded_namespaces              = optional(list(string), [])
    included_namespaces              = optional(list(string), [])
    excluded_resource_types          = optional(list(string), [])
    included_resource_types          = optional(list(string), [])
    label_selectors                  = optional(list(string), [])
    cluster_scoped_resources_enabled = optional(bool, false)
    volume_snapshot_enabled          = optional(bool, false)
  })
  default     = null
  description = "Configuration for Kubernetes backup datasource parameters."
}

# Backup Instances Configuration
variable "backup_instances" {
  type = map(object({
    type              = string # "disk", "blob", "kubernetes", "postgresql", "postgresql_flexible"
    name              = string
    backup_policy_key = string # References key from backup_policies map

    # Disk-specific settings
    disk_id                      = optional(string)
    snapshot_resource_group_name = optional(string)

    # Blob-specific settings
    storage_account_id              = optional(string)
    storage_account_container_names = optional(list(string), [])

    # AKS-specific settings
    kubernetes_cluster_id = optional(string)
    backup_datasource_parameters = optional(object({
      excluded_namespaces              = optional(list(string), [])
      included_namespaces              = optional(list(string), [])
      excluded_resource_types          = optional(list(string), [])
      included_resource_types          = optional(list(string), [])
      label_selectors                  = optional(list(string), [])
      cluster_scoped_resources_enabled = optional(bool, false)
      volume_snapshot_enabled          = optional(bool, false)
    }))

    # PostgreSQL-specific settings
    postgresql_server_id           = optional(string)
    postgresql_database_id         = optional(string)
    postgresql_key_vault_secret_id = optional(string)

    # PostgreSQL Flexible-specific settings
    postgresql_flexible_server_id           = optional(string)
    postgresql_flexible_database_id         = optional(string)
    postgresql_flexible_key_vault_secret_id = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
Map of backup instances to create. Each instance references a backup policy via backup_policy_key.

Supported types: "disk", "blob", "kubernetes", "postgresql", "postgresql_flexible"

Common settings:
- name: Display name for the backup instance
- backup_policy_key: Reference to a key in backup_policies map

Type-specific settings:
- Disk: disk_id, snapshot_resource_group_name
- Blob: storage_account_id, storage_account_container_names
- AKS: kubernetes_cluster_id, backup_datasource_parameters
- PostgreSQL: postgresql_server_id, postgresql_database_id, postgresql_key_vault_secret_id
- PostgreSQL Flexible: postgresql_flexible_server_id, postgresql_flexible_database_id, postgresql_flexible_key_vault_secret_id
DESCRIPTION

  validation {
    condition = alltrue([
      for instance in var.backup_instances :
      contains(["disk", "blob", "kubernetes", "postgresql", "postgresql_flexible"], instance.type)
    ])
    error_message = "All backup instances must have a valid type: disk, blob, kubernetes, postgresql, or postgresql_flexible."
  }
  validation {
    condition = alltrue([
      for instance in var.backup_instances :
      contains(keys(var.backup_policies), instance.backup_policy_key)
    ])
    error_message = "All backup instances must reference existing backup policy keys from the backup_policies variable."
  }
  validation {
    condition = alltrue([
      for instance in var.backup_instances :
      contains(keys(var.backup_policies), instance.backup_policy_key) ?
      var.backup_policies[instance.backup_policy_key].type == instance.type :
      true
    ])
    error_message = "All backup instances must have the same type as their referenced backup policy."
  }
  validation {
    condition = alltrue([
      for instance in var.backup_instances :
      length(instance.name) >= 5 && length(instance.name) <= 50
    ])
    error_message = "All backup instance names must be between 5 and 50 characters long."
  }
}

# Backup Policies Configuration
variable "backup_policies" {
  type = map(object({
    type = string # "disk", "blob", "kubernetes", "postgresql", "postgresql_flexible"
    name = string

    # Common policy settings
    backup_repeating_time_intervals = optional(list(string), [])
    default_retention_duration      = optional(string, "P30D")
    time_zone                       = optional(string, "UTC")

    # Disk-specific settings
    # (all settings are shared with other types for consistency)

    # Blob-specific settings
    operational_default_retention_duration = optional(string)
    vault_default_retention_duration       = optional(string)

    # AKS-specific settings
    default_retention_life_cycle = optional(object({
      data_store_type = optional(string, "OperationalStore")
      duration        = optional(string, "P14D")
    }))

    # Retention rules (common to all types)
    retention_rules = optional(list(object({
      name     = string
      priority = number
      duration = optional(string, "P30D")
      criteria = list(object({
        absolute_criteria      = optional(string)
        days_of_month          = optional(list(number))
        days_of_week           = optional(list(string))
        months_of_year         = optional(list(string))
        scheduled_backup_times = optional(list(string))
        weeks_of_month         = optional(list(string))
      }))
      # Life cycle (for blob policies)
      life_cycle = optional(list(object({
        data_store_type = string
        duration        = string
      })), [])
    })), [])
  }))
  default     = {}
  description = <<DESCRIPTION
Map of backup policies to create. Each policy can be referenced by backup instances.
Key is used as reference identifier for backup instances.

Supported types: "disk", "blob", "kubernetes", "postgresql", "postgresql_flexible"

Common settings:
- backup_repeating_time_intervals: List of ISO8601 backup schedule intervals
- default_retention_duration: Default retention period in ISO8601 format
- time_zone: Time zone for backup schedules
- retention_rules: List of retention rules with criteria and lifecycle

Type-specific settings:
- Blob: operational_default_retention_duration, vault_default_retention_duration
- AKS: default_retention_life_cycle with data_store_type and duration
DESCRIPTION

  validation {
    condition = alltrue([
      for policy in var.backup_policies :
      contains(["disk", "blob", "kubernetes", "postgresql", "postgresql_flexible"], policy.type)
    ])
    error_message = "All backup policies must have a valid type: disk, blob, kubernetes, postgresql, or postgresql_flexible."
  }
}

variable "backup_repeating_time_intervals" {
  type        = list(string)
  default     = []
  description = "List of repeating time intervals for scheduling backups."
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

variable "default_retention_life_cycle" {
  type = object({
    data_store_type = optional(string, "OperationalStore")
    duration        = optional(string, "P14D")
  })
  default     = null
  description = "Default retention life cycle configuration for AKS backups."
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

# Enable telemetry for the module
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

variable "immutability" {
  type        = string
  default     = "Disabled"
  description = "Immutability state: Disabled, Locked, or Unlocked."

  validation {
    condition     = contains(["Disabled", "Locked", "Unlocked"], var.immutability)
    error_message = "immutability must be one of: Disabled, Locked, Unlocked."
  }
}

variable "kubernetes_backup_instance_name" {
  type        = string
  default     = null
  description = "Name for the AKS backup instance when using direct configuration."
}

variable "kubernetes_backup_policy_name" {
  type        = string
  default     = null
  description = "Name for the AKS backup policy when using direct configuration."
}

variable "kubernetes_cluster_id" {
  type        = string
  default     = null
  description = "Resource ID of the AKS cluster to back up when using direct configuration."
}

variable "kubernetes_retention_rules" {
  type = list(object({
    name              = string
    priority          = number
    absolute_criteria = optional(string)
    days_of_week      = optional(list(string))
    months_of_year    = optional(list(string))
    weeks_of_month    = optional(list(string))
    data_store_type   = optional(string, "OperationalStore")
    duration          = string
  }))
  default     = []
  description = "List of retention rules for AKS backups when using direct configuration."
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

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    scope                                  = optional(string)
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on resources. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `scope` - (Optional) The scope at which the role assignment applies to. Defaults to the backup vault resource ID.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.
  DESCRIPTION
  nullable    = false
}

variable "snapshot_resource_group_name" {
  type        = string
  default     = null
  description = "Resource group name for AKS volume snapshots when using direct configuration."
}

variable "soft_delete" {
  type        = string
  default     = "Off"
  description = <<DESCRIPTION
The state of soft delete for this Backup Vault. Valid options: AlwaysOn, Off, On. Defaults to On.
Once set to AlwaysOn, the setting cannot be changed.
DESCRIPTION

  validation {
    condition     = contains(["AlwaysOn", "Off", "On"], var.soft_delete)
    error_message = "soft_delete must be one of: AlwaysOn, Off, On."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "time_zone" {
  type        = string
  default     = "UTC"
  description = "Time zone for backup scheduling when using direct configuration."
}

# Timeouts Configuration
variable "timeout_create" {
  type        = string
  default     = "30m"
  description = "The timeout duration for creating resources."
}

variable "timeout_delete" {
  type        = string
  default     = "30m"
  description = "The timeout duration for deleting resources."
}

variable "timeout_read" {
  type        = string
  default     = "5m"
  description = "The timeout duration for reading resources."
}

variable "timeout_update" {
  type        = string
  default     = "30m"
  description = "The timeout duration for updating resources."
}
