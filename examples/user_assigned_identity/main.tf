terraform {
  required_version = "~> 1.9.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0, < 5.0"
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
  suffix  = ["test"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Create a User-Assigned Managed Identity
resource "azurerm_user_assigned_identity" "example" {
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.resource_group.name_unique}-identity"
  resource_group_name = azurerm_resource_group.example.name
}

# Call the Backup Vault Module and assign the User-Assigned Managed Identity
module "backup_vault" {
  source              = "../../" # Replace with correct module path
  location            = azurerm_resource_group.example.location
  name                = module.naming.recovery_services_vault.name_unique
  resource_group_name = azurerm_resource_group.example.name

  # Minimum required variables
  datastore_type   = "VaultStore"
  redundancy       = "GeoRedundant"
  enable_telemetry = true

  # Assign the User-Assigned Managed Identity
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example.id]
  }
}

# Assign Role for the Managed Identity
resource "azurerm_role_assignment" "this" {
  principal_id         = azurerm_user_assigned_identity.example.principal_id
  scope                = azurerm_resource_group.example.id
  role_definition_name = "Contributor"
}
