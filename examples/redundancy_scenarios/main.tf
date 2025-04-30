terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
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

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["redundancy"]

}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = local.test_regions.primary_region
  name     = module.naming.resource_group.name_unique
}

# Geo-redundant with cross-region restore enabled
module "backup_vault_geo_redundant_with_cross_restore" {
  source                       = "../../"
  location                     = local.test_regions.primary_region
  name                         = "${module.naming.recovery_services_vault.name_unique}-geo-cross"
  resource_group_name          = azurerm_resource_group.example.name
  datastore_type               = "VaultStore"
  redundancy                   = "GeoRedundant"
  cross_region_restore_enabled = true # Only works with GeoRedundant
  soft_delete                  = "On"
  retention_duration_in_days   = 30
  enable_telemetry             = true
}

# Geo-redundant without cross-region restore
module "backup_vault_geo_redundant_no_cross_restore" {
  source                       = "../../"
  location                     = local.test_regions.primary_region
  name                         = "${module.naming.recovery_services_vault.name_unique}-geo-no-cross"
  resource_group_name          = azurerm_resource_group.example.name
  datastore_type               = "VaultStore"
  redundancy                   = "GeoRedundant"
  cross_region_restore_enabled = false
  soft_delete                  = "On"
  retention_duration_in_days   = 30
  enable_telemetry             = true
}

# Locally redundant
module "backup_vault_locally_redundant" {
  source                     = "../../"
  location                   = local.test_regions.primary_region
  name                       = "${module.naming.recovery_services_vault.name_unique}-local"
  resource_group_name        = azurerm_resource_group.example.name
  datastore_type             = "VaultStore"
  redundancy                 = "LocallyRedundant"
  soft_delete                = "On"
  retention_duration_in_days = 45
  enable_telemetry           = true
}

# Zone redundant (if available in the region)
module "backup_vault_zone_redundant" {
  source                     = "../../"
  location                   = local.test_regions.primary_region
  name                       = "${module.naming.recovery_services_vault.name_unique}-zone"
  resource_group_name        = azurerm_resource_group.example.name
  datastore_type             = "VaultStore"
  redundancy                 = "ZoneRedundant"
  soft_delete                = "On"
  retention_duration_in_days = 60
  enable_telemetry           = true
}

# Define regions for redundancy options
locals {
  test_regions = {
    primary_region  = "eastus"  # Primary region with all redundancy options
    paired_region   = "westus"  # Paired region for geo-redundant testing
    fallback_region = "eastus2" # Fallback if primary isn't available
  }
}
