terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0, < 1.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

# Randomly select an Azure region for the resource group
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.7.0"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["adls"]
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  location = "centralus"
  name     = module.naming.resource_group.name_unique
}

# Create an ADLS Gen2 Storage Account (hierarchical namespace enabled)
resource "azurerm_storage_account" "example" {
  account_replication_type        = "ZRS"
  account_tier                    = "Standard"
  location                        = azurerm_resource_group.example.location
  name                            = module.naming.storage_account.name_unique
  resource_group_name             = azurerm_resource_group.example.name
  allow_nested_items_to_be_public = false
  is_hns_enabled                  = true
  shared_access_key_enabled       = false
}

# Create a Storage Container (filesystem) in ADLS Gen2
resource "azurerm_storage_container" "example" {
  name                  = "example-filesystem"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.example.id
}

# Create a time_sleep resource to wait
resource "time_sleep" "wait_for_lock_release" {
  destroy_duration = "180s"

  depends_on = [
    azurerm_storage_container.example,
    azurerm_storage_account.example
  ]
}

# Module Call for Backup Vault
module "backup_vault" {
  source = "../../"

  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.recovery_services_vault.name_unique}-vault"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.example.name
  # Define backup instance
  backup_instances = {
    "adls-instance" = {
      type                            = "adls"
      name                            = "${module.naming.recovery_services_vault.name_unique}-adls-instance"
      backup_policy_key               = "adls-backup"
      storage_account_id              = azurerm_storage_account.example.id
      storage_account_container_names = [azurerm_storage_container.example.name]
    }
  }
  # Define backup policy
  backup_policies = {
    "adls-backup" = {
      type                             = "adls"
      name                             = "${module.naming.recovery_services_vault.name_unique}-backup-policy"
      backup_repeating_time_intervals  = ["R/2024-09-17T06:33:16+00:00/P1D"]
      vault_default_retention_duration = "P90D"
      time_zone                        = "Central Standard Time"
      retention_rules = [
        {
          name     = "Daily"
          duration = "P7D"
          priority = 25
          criteria = [{
            absolute_criteria = "FirstOfDay"
          }]
          life_cycle = [{
            data_store_type = "VaultStore"
            duration        = "P30D"
          }]
        },
        {
          name     = "Weekly"
          duration = "P7D"
          priority = 20
          criteria = [{
            absolute_criteria = "FirstOfWeek"
          }]
          life_cycle = [{
            data_store_type = "VaultStore"
            duration        = "P30D"
          }]
        }
      ]
    }
  }
  enable_telemetry = true
  lock             = null
  managed_identities = {
    system_assigned = true
  }
  soft_delete = "Off"

  depends_on = [time_sleep.wait_for_lock_release]
}

resource "azurerm_role_assignment" "storage_account_backup_contributor" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_resource_group.example.id
  description          = "Backup Contributor for ADLS Gen2 Storage"
  role_definition_name = "Storage Account Backup Contributor"
}

