terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "time" {}

# Naming
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  location = "eastus"
  name     = module.naming.resource_group.name_unique
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  location                    = azurerm_resource_group.rg.location
  name                        = module.naming.key_vault.name_unique
  resource_group_name         = azurerm_resource_group.rg.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
}

# Grant current user permissions to manage the key
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.kv.id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  key_permissions = [
    "Get", "List", "Create", "Delete", "Recover", "Purge", "Update",
    "GetRotationPolicy", "SetRotationPolicy"
  ]
}

data "azurerm_client_config" "current" {}

# Key
resource "azurerm_key_vault_key" "key" {
  key_opts     = ["decrypt", "encrypt", "unwrapKey", "wrapKey", "sign", "verify"]
  key_type     = "RSA"
  key_vault_id = azurerm_key_vault.kv.id
  name         = "backup-vault-cmk"
  key_size     = 2048

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Module under test
module "backup_vault" {
  source = "../../"

  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.rg.location
  name                = module.naming.recovery_services_vault.name_unique
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.rg.name
  diagnostic_settings = {}
  enable_telemetry    = true
  managed_identities = {
    system_assigned = true
  }
}

# Access policy for the vault MI (created after the vault exists)
resource "azurerm_key_vault_access_policy" "vault_mi" {
  key_vault_id    = azurerm_key_vault.kv.id
  object_id       = module.backup_vault.identity_principal_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  key_permissions = ["Get", "WrapKey", "UnwrapKey"]

  depends_on = [module.backup_vault]
}

# Wait for access policy propagation before enabling CMK
resource "time_sleep" "wait_policy" {
  create_duration = "30s"

  depends_on = [azurerm_key_vault_access_policy.vault_mi]
}

# Configure CMK on the backup vault in one shot (outside the module)
resource "azurerm_data_protection_backup_vault_customer_managed_key" "cmk" {
  data_protection_backup_vault_id = module.backup_vault.resource_id
  key_vault_key_id                = azurerm_key_vault_key.key.versionless_id

  depends_on = [time_sleep.wait_policy]
}
