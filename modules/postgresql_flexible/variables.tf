variable "location" {
  type        = string
  description = "Azure region used for backup instances."
  nullable    = false
}

variable "timeout_create" {
  type        = string
  description = "Create timeout."
}

variable "timeout_delete" {
  type        = string
  description = "Delete timeout."
}

variable "timeout_read" {
  type        = string
  description = "Read timeout."
}

variable "timeout_update" {
  type        = string
  description = "Update timeout."
}

variable "vault_id" {
  type        = string
  description = "Resource ID of the Data Protection Backup Vault."
  nullable    = false
}

variable "instances" {
  type = map(object({
    name                          = string
    backup_policy_key             = string
    postgresql_flexible_server_id = optional(string)
  }))
  default     = {}
  description = "PostgreSQL Flexible backup instances keyed by stable identifier."
}

variable "policies" {
  type = map(object({
    name                            = string
    backup_repeating_time_intervals = optional(list(string), [])
    default_retention_duration      = optional(string, "P30D")
    time_zone                       = optional(string, "UTC")

    retention_rules = optional(list(object({
      name     = string
      priority = number

      criteria = list(object({
        absolute_criteria      = optional(string)
        days_of_week           = optional(list(string))
        months_of_year         = optional(list(string))
        scheduled_backup_times = optional(list(string))
        weeks_of_month         = optional(list(string))
      }))

      life_cycle = optional(list(object({
        data_store_type = string
        duration        = string
      })), [])
    })), [])
  }))
  default     = {}
  description = "PostgreSQL Flexible backup policies keyed by stable identifier."
}
