variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "subscription_id" {
  description = "Subscription ID to be used"
  type        = string
  default = "b4b418d1-7fb5-41a9-952d-ffbff78e61b6"
}

