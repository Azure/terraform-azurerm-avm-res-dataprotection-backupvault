terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"

  suffix = ["cmk", "test"]
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  location = "eastus"
  name     = module.naming.resource_group.name_unique
}

# Create a User Assigned Managed Identity for Key Vault access
resource "azurerm_user_assigned_identity" "example" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.example.name
}

# Create Key Vault
resource "azurerm_key_vault" "example" {
  location                    = azurerm_resource_group.example.location
  name                        = module.naming.key_vault.name_unique
  resource_group_name         = azurerm_resource_group.example.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  enabled_for_disk_encryption = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.example.principal_id

    key_permissions = [
      "Get",
      "WrapKey",
      "UnwrapKey"
    ]
  }
}

# Create Key Vault Key
resource "azurerm_key_vault_key" "example" {
  key_vault_id = azurerm_key_vault.example.id
  name         = "backup-vault-cmk"
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault.example]
}

# Call the Backup Vault Module with CMK
module "backup_vault" {
  source = "../../" # Replace with correct module path

  # Minimum required variables
  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = module.naming.recovery_services_vault.name_unique
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.example.name
  
  # Customer Managed Key configuration
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.example.id
    key_name              = azurerm_key_vault_key.example.name
    key_version           = null # Use latest version
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.example.id
    }
  }

  # Managed identity for backup vault
  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example.id]
  }

  diagnostic_settings = {}
  enable_telemetry    = true # Enable telemetry (optional)

  depends_on = [
    azurerm_key_vault_key.example,
    azurerm_user_assigned_identity.example
  ]
}