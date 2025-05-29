# PostgreSQL Backup Policy Variables
variable "postgresql_backup_instance_name" {
  type        = string
  default     = null
  description = "The name of the Backup Instance PostgreSQL."
}

variable "postgresql_backup_policy_id" {
  type        = string
  default     = null
  description = "The ID of the Backup Policy PostgreSQL."
}

variable "postgresql_database_id" {
  type        = string
  default     = null
  description = "The ID of the source PostgreSQL database."
}

variable "postgresql_key_vault_secret_id" {
  type        = string
  default     = null
  description = "The ID of the key vault secret that stores the database credentials."
}
