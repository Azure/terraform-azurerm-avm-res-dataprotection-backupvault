
module "postgresql_flexible" {
  source = "./modules/postgresql_flexible"

  location       = var.location
  timeout_create = var.timeout_create
  timeout_delete = var.timeout_delete
  timeout_read   = var.timeout_read
  timeout_update = var.timeout_update
  vault_id       = azapi_resource.backup_vault.id
  instances      = local.postgresql_flexible_instances
  policies       = local.postgresql_flexible_policies
}
