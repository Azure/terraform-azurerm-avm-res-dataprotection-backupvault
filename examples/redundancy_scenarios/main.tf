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
  version = "0.1.0"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["redundancy"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = local.test_regions.primary_region
  name     = module.naming.resource_group.name_unique
}

# Geo-redundant with cross-region restore enabled
module "backup_vault_geo_redundant_with_cross_restore" {
  source = "../../"

  datastore_type               = "VaultStore"
  location                     = local.test_regions.primary_region
  name                         = "${module.naming.recovery_services_vault.name_unique}-geo-cross"
  redundancy                   = "GeoRedundant"
  resource_group_name          = azurerm_resource_group.example.name
  cross_region_restore_enabled = true # Only works with GeoRedundant
  enable_telemetry             = true
  retention_duration_in_days   = 30
  soft_delete                  = "On"
}

# Geo-redundant without cross-region restore
module "backup_vault_geo_redundant_no_cross_restore" {
  source = "../../"

  datastore_type               = "VaultStore"
  location                     = local.test_regions.primary_region
  name                         = "${module.naming.recovery_services_vault.name_unique}-geo-no-cross"
  redundancy                   = "GeoRedundant"
  resource_group_name          = azurerm_resource_group.example.name
  cross_region_restore_enabled = false
  enable_telemetry             = true
  retention_duration_in_days   = 30
  soft_delete                  = "On"
}

# Locally redundant
module "backup_vault_locally_redundant" {
  source = "../../"

  datastore_type             = "VaultStore"
  location                   = local.test_regions.primary_region
  name                       = "${module.naming.recovery_services_vault.name_unique}-local"
  redundancy                 = "LocallyRedundant"
  resource_group_name        = azurerm_resource_group.example.name
  enable_telemetry           = true
  retention_duration_in_days = 45
  soft_delete                = "On"
}

# Zone redundant (if available in the region)
module "backup_vault_zone_redundant" {
  source = "../../"

  datastore_type             = "VaultStore"
  location                   = local.test_regions.primary_region
  name                       = "${module.naming.recovery_services_vault.name_unique}-zone"
  redundancy                 = "ZoneRedundant"
  resource_group_name        = azurerm_resource_group.example.name
  enable_telemetry           = true
  retention_duration_in_days = 60
  soft_delete                = "On"
}

# Define regions for redundancy options
locals {
  test_regions = {
    primary_region  = "eastus"  # Primary region with all redundancy options
    paired_region   = "westus"  # Paired region for geo-redundant testing
    fallback_region = "eastus2" # Fallback if primary isn't available
  }
}
