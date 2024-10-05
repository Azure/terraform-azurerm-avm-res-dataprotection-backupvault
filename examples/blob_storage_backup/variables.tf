variable "diagnostic_settings" {
  type = map(object({
    name                       = optional(string, null)
    log_categories             = optional(set(string), [])
    metric_categories          = optional(set(string), ["AllMetrics"])
    log_analytics_workspace_id = optional(string, null)
    storage_account_id         = optional(string, null)
  }))
  default     = {}
  description = "Diagnostic settings for resources"
}
