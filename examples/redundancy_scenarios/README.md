<!-- BEGIN_TF_DOCS -->
# Redundancy Scenarios Example

This deploys the Backup Vault module with different redundancy options, testing LocallyRedundant, GeoRedundant, and ZoneRedundant settings.

```hcl
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

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.110.0, < 5.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_backup_vault_geo_redundant_no_cross_restore"></a> [backup\_vault\_geo\_redundant\_no\_cross\_restore](#module\_backup\_vault\_geo\_redundant\_no\_cross\_restore)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: ~> 0.1

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->