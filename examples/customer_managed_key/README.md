# Customer Managed Key Example

This example demonstrates how to deploy an Azure Data Protection Backup Vault with Customer Managed Key (CMK) encryption.

## Features

- Creates a backup vault with customer managed key encryption
- Sets up a Key Vault with appropriate access policies
- Creates a user-assigned managed identity for key access
- Configures encryption using a customer managed key from Key Vault

## Resources

- Azure Data Protection Backup Vault
- Key Vault with purge protection enabled
- Key Vault Key for encryption
- User Assigned Managed Identity
- Appropriate access policies for key operations

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.7.0
- Azure CLI or appropriate Azure authentication

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
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.example.id
    }
  }

  # Enable user-assigned managed identity
  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example.id]
  }
}
```

## Important Notes

1. **Key Vault Requirements:**
   - Purge protection must be enabled
   - Soft delete must be enabled
   - Appropriate access policies for the managed identity

2. **Managed Identity:**
   - Must have `Get`, `WrapKey`, and `UnwrapKey` permissions on the Key Vault
   - Must be assigned to the backup vault

3. **Key Requirements:**
   - RSA key type with minimum 2048-bit size
   - Must have `wrapKey` and `unwrapKey` operations enabled

## Security Considerations

- The Key Vault is configured with purge protection to prevent accidental deletion
- Access policies are configured with minimal required permissions
- User-assigned managed identity provides secure access to encryption keys