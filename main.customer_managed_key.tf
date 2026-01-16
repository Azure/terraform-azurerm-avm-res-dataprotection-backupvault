# Customer Managed Key for encryption of the backup vault
resource "azapi_update_resource" "cmk" {
  count = var.customer_managed_key != null ? 1 : 0

  resource_id = azapi_resource.backup_vault.id
  type        = azapi_resource.backup_vault.type
  body = {
    properties = {
      securitySettings = {
        encryptionSettings = {
          state = "Enabled"
          keyVaultProperties = {
            keyUri = var.customer_managed_key.key_version != null && var.customer_managed_key.key_version != "" ? format("https://%s.vault.azure.net/keys/%s/%s", element(split("/vaults/", var.customer_managed_key.key_vault_resource_id), 1), var.customer_managed_key.key_name, var.customer_managed_key.key_version) : format("https://%s.vault.azure.net/keys/%s", element(split("/vaults/", var.customer_managed_key.key_vault_resource_id), 1), var.customer_managed_key.key_name)
          }
          kekIdentity = var.customer_managed_key.user_assigned_identity != null ? {
            identityType = "UserAssigned"
            identityId   = var.customer_managed_key.user_assigned_identity.resource_id
          } : null
        }
      }
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
