# PostgreSQL Backup Policy Variables
variable "postgresql_backup_instance_name" {
  description = "The name of the Backup Instance PostgreSQL."
  type        = string
  default     = null
}

variable "postgresql_database_id" {
  description = "The ID of the source PostgreSQL database."
  type        = string
  default     = null
}

variable "postgresql_backup_policy_id" {
  description = "The ID of the Backup Policy PostgreSQL."
  type        = string
  default     = null
}

variable "postgresql_key_vault_secret_id" {
  description = "The ID of the key vault secret that stores the database credentials."
  type        = string
  default     = null
}
