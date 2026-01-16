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
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

# Naming
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  location = "centralus"
  name     = "${module.naming.resource_group.name_unique}-uai"
}

# Create User-Assigned Managed Identity
resource "azurerm_user_assigned_identity" "backup_vault_identity" {
  location            = azurerm_resource_group.rg.location
  name                = "${module.naming.user_assigned_identity.name_unique}-backup"
  resource_group_name = azurerm_resource_group.rg.name
}

# Backup Vault with User-Assigned Identity Only
module "backup_vault_user_assigned_only" {
  source = "../../"

  datastore_type      = "OperationalStore"
  location            = azurerm_resource_group.rg.location
  name                = "${module.naming.recovery_services_vault.name_unique}-uai"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.rg.name
  diagnostic_settings = {}
  enable_telemetry    = true
  # User-Assigned Identity Only
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.backup_vault_identity.id]
  }
}

# Backup Vault with Both System-Assigned and User-Assigned Identity
module "backup_vault_both_identities" {
  source = "../../"

  datastore_type      = "OperationalStore"
  location            = azurerm_resource_group.rg.location
  name                = "${module.naming.recovery_services_vault.name_unique}-both"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.rg.name
  diagnostic_settings = {}
  enable_telemetry    = true
  # Both System-Assigned and User-Assigned Identity
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.backup_vault_identity.id]
  }
}

