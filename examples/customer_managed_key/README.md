# Customer Managed Key Example

This example demonstrates how to deploy an Azure Data Protection Backup Vault with Customer Managed Key (CMK) encryption.

## Features

- Creates a backup vault with customer managed key encryption
- Sets up a Key Vault with appropriate access policies
- Uses the backup vault's system-assigned managed identity for key access
- Configures encryption using a customer managed key from Key Vault

## Important Notes

**Identity Limitations:**
- Azure Data Protection Backup Vault only supports system-assigned managed identity
- User-assigned managed identities are not supported by this resource type
- The backup vault's system-assigned identity is automatically granted access to the Key Vault

**Key Vault Requirements:**
- Purge protection must be enabled
- Soft delete must be enabled  
- The backup vault's system-assigned identity needs `Get`, `WrapKey`, and `UnwrapKey` permissions

## Resources

- Azure Data Protection Backup Vault with system-assigned identity
- Key Vault with purge protection enabled
- Key Vault Key for encryption
- Key Vault Access Policy for backup vault identity

## Usage

```hcl
module "backup_vault" {
  source = "Azure/avm-res-dataprotection-backupvault/azurerm"

  datastore_type      = "VaultStore"
  location            = "East US"
  name                = "example-backup-vault"
  redundancy          = "LocallyRedundant"
  resource_group_name = "example-rg"
  
  # Customer Managed Key configuration
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.example.id
    key_name              = "backup-vault-cmk"
    key_version           = null # Use latest version
    # Note: user_assigned_identity is not supported
  }

  # Enable system-assigned managed identity
  managed_identities = {
    system_assigned = true
  }
}

# Grant backup vault identity access to Key Vault
resource "azurerm_key_vault_access_policy" "backup_vault" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.backup_vault.identity_principal_id

  key_permissions = [
    "Get",
    "WrapKey", 
    "UnwrapKey"
  ]
}
```