terraform {
  required_version = "~> 1.9.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0, < 5.0"
    }
    # modtm = {
    #   source  = "azure/modtm"
    #   version = "~> 0.3"
    # }
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
  suffix  = ["test"]

}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Call the Backup Vault Module
# module "backup_vault_geo_redundant" {
#   source              = "../../" # Replace with correct module path
#   location            = azurerm_resource_group.example.location
#   name                = module.naming.recovery_services_vault.name_unique
#   resource_group_name = azurerm_resource_group.example.name

#   datastore_type      = "VaultStore"
#   redundancy          = "GeoRedundant"
#   cross_region_restore_enabled = true  # This only works when redundancy is GeoRedundant

#   # Enable soft delete and set a custom retention duration
#   soft_delete                 = "On"
#   retention_duration_in_days  = 30

#   enable_telemetry = true
# }

module "backup_vault_geo_redundant_no_cross_restore" {
  source              = "../../" # Replace with correct module path
  location            = azurerm_resource_group.example.location
  name                = module.naming.recovery_services_vault.name_unique
  resource_group_name = azurerm_resource_group.example.name

  datastore_type               = "VaultStore"
  redundancy                   = "GeoRedundant"
  cross_region_restore_enabled = false # Explicitly set to false

  # Enable soft delete and set a custom retention duration
  soft_delete                = "On"
  retention_duration_in_days = 30

  enable_telemetry = true
}

# module "backup_vault_locally_redundant" {
#   source              = "../../" # Replace with correct module path
#   location            = azurerm_resource_group.example.location
#   name                = module.naming.recovery_services_vault.name_unique
#   resource_group_name = azurerm_resource_group.example.name

#   datastore_type      = "VaultStore"
#   redundancy          = "LocallyRedundant" # No cross-region restore applicable here

#   # Enable soft delete and set a custom retention duration
#   soft_delete                 = "On"
#   retention_duration_in_days  = 45

#   enable_telemetry = true
# }

# module "backup_vault_zone_redundant" {
#   source              = "../../" # Replace with correct module path
#   location            = azurerm_resource_group.example.location
#   name                = module.naming.recovery_services_vault.name_unique
#   resource_group_name = azurerm_resource_group.example.name

#   datastore_type      = "VaultStore"
#   redundancy          = "ZoneRedundant" # No cross-region restore applicable

#   # Enable soft delete and set a custom retention duration
#   soft_delete                 = "On"
#   retention_duration_in_days  = 60

#   enable_telemetry = true
# }

