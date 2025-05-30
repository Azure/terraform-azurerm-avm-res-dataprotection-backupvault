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
  default     = {}
  description = "Parameters to customize which resources/namespaces are included or excluded from AKS backups."
}

variable "kubernetes_backup_instance_name" {
  type        = string
  default     = null
  description = "Name for the Kubernetes Cluster backup instance."
}

variable "kubernetes_backup_policy_id" {
  type        = string
  default     = null
  description = "If set, uses this existing backup policy ID instead of creating one."
}

variable "kubernetes_backup_policy_name" {
  type        = string
  default     = null
  description = "Name for the Kubernetes Cluster backup policy."
}

variable "kubernetes_cluster_id" {
  type        = string
  default     = null
  description = "ID of the Kubernetes Cluster to back up."
}

variable "kubernetes_retention_rules" {
  type = list(object({
    name                   = string
    priority               = number
    absolute_criteria      = optional(string)
    days_of_week           = optional(list(string))
    months_of_year         = optional(list(string))
    scheduled_backup_times = optional(list(string))
    weeks_of_month         = optional(list(string))
    data_store_type        = optional(string, "OperationalStore")
    duration               = string
  }))
  default     = []
  description = "List of retention rules specific to AKS backup policy"
}
