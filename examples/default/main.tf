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
  features {}
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"

  suffix = ["test"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = "eastus"
  name     = module.naming.resource_group.name_unique
}

# Call the Backup Vault Module
module "backup_vault" {
  source = "../../" # Replace with correct module path

  # Minimum required variables
  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = module.naming.recovery_services_vault.name_unique
  redundancy          = "GeoRedundant"
  resource_group_name = azurerm_resource_group.example.name
  diagnostic_settings = {}
  enable_telemetry    = true # Enable telemetry (optional)
}
