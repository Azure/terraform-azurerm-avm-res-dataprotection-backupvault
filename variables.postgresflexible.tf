# PostgreSQL Flexible Server variables
variable "postgresql_flexible_backup_instance_name" {
  type        = string
  default     = null
  description = "The name of the PostgreSQL Flexible Server Backup Instance."

  validation {
    condition     = var.postgresql_flexible_backup_instance_name != null ? (length(var.postgresql_flexible_backup_instance_name) >= 5 && length(var.postgresql_flexible_backup_instance_name) <= 50) : true
    error_message = "The name must be between 5 and 50 characters long if provided."
  }
}

variable "postgresql_flexible_backup_policy_id" {
  type        = string
  default     = null
  description = "The ID of the PostgreSQL Flexible Server Backup Policy to use. If not provided, the module will create a policy."
}

variable "postgresql_backup_policy_name" {
  type        = string
  default     = null
  description = "The name of the PostgreSQL Flexible Server Backup Policy."
}

variable "postgresql_flexible_server_id" {
  type        = string
  default     = null
  description = "The ID of the PostgreSQL Flexible Server to be backed up."
}

variable "pg_retention_rules" {
  type = list(object({
    name                   = string
    priority               = number
    duration               = string
    data_store_type        = optional(string, "VaultStore")
    absolute_criteria      = optional(string)
    days_of_week           = optional(list(string))
    months_of_year         = optional(list(string))
    scheduled_backup_times = optional(list(string))
    weeks_of_month         = optional(list(string))
  }))
  default     = []
  description = "List of retention rules for PostgreSQL flexible server backup policy."

  validation {
    condition = alltrue([
      for rule in var.pg_retention_rules :
      rule.absolute_criteria != null ||
      (rule.days_of_week != null && rule.scheduled_backup_times != null) ||
      (rule.weeks_of_month != null && rule.days_of_week != null && rule.scheduled_backup_times != null)
    ])
    error_message = "Each retention rule must have either absolute_criteria OR days_of_week with scheduled_backup_times OR weeks_of_month with days_of_week and scheduled_backup_times."
  }
}
