output "backup_instance_ids" {
  description = "Map of PostgreSQL Flexible backup instance IDs by instance key."
  value       = { for k, v in azurerm_data_protection_backup_instance_postgresql_flexible_server.this : k => v.id }
}

output "backup_policy_ids" {
  description = "Map of PostgreSQL Flexible backup policy IDs by policy key."
  value       = { for k, v in azurerm_data_protection_backup_policy_postgresql_flexible_server.this : k => v.id }
}
