terraform {
  required_version = "~> 1.9.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0, < 5.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

# Randomly select an Azure region for the resource group
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["blob"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Create a Storage Account for Blob Storage
resource "azurerm_storage_account" "example" {
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Storage Container
resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

# Module Call
module "backup_vault" {
  source = "../../"

  location                       = azurerm_resource_group.example.location
  name                           = "${module.naming.recovery_services_vault.name_unique}-vault"
  resource_group_name            = azurerm_resource_group.example.name
  datastore_type                 = "VaultStore"
  redundancy                     = "LocallyRedundant"
  vault_default_retention_duration = "P90D"
  operational_default_retention_duration = "P30D"
  identity_enabled               = true
  enable_telemetry               = true

  # Inputs for backup policy and backup instance
  backup_policy_name             = "${module.naming.recovery_services_vault.name_unique}-backup-policy"
  blob_backup_instance_name      = "${module.naming.recovery_services_vault.name_unique}-blob-instance"
  storage_account_id             = azurerm_storage_account.example.id
  backup_policy_id               = module.backup_vault.backup_policy_id

  storage_account_container_names = [azurerm_storage_container.example.name]

  role_assignments = {
    example_assignment = {
      principal_id = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Storage Account Backup Contributor"
      scope = azurerm_storage_account.example.id
    }
  }

  # Valid repeating intervals for backup
  backup_repeating_time_intervals = ["R/2024-09-17T06:33:16+00:00/PT4H"]
  time_zone                       = "Central Standard Time"

  # Define the retention rules list here
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
        duration        = "P30D"  # Specify a valid retention duration here
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
        duration        = "P30D"  # Specify a valid retention duration here
      }]
    }
  ]
}
