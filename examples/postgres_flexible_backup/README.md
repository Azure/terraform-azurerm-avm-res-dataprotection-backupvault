<!-- BEGIN_TF_DOCS -->
# Blob Backup Storage Example

This example demonstrates how to deploy the `azurerm_data_protection_backup_vault` module with a blob backup instance, backup policy, and storage account for a comprehensive data protection solution.

```hcl
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

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# Random region selection
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["disk"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Create a PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "example" {
  location               = azurerm_resource_group.example.location
  name                   = module.naming.postgresql_server.name_unique
  resource_group_name    = azurerm_resource_group.example.name
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  sku_name               = "GP_Standard_D4s_v3"
  storage_mb             = 32768
  version                = "12"
  zone                   = "2"

  # High Availability configuration with zone redundancy
  high_availability {
    mode                      = "ZoneRedundant" # Required, can be "ZoneRedundant" or "SameZone"
    standby_availability_zone = "1"             # Specify a different zone for the standby replica
  }
  # Define a custom maintenance window
  maintenance_window {
    day_of_week = 0
    start_hour  = 2
  }
}

# Call PostgreSQL Flexible Backup Vault and Backup Policy
module "backup_vault" {
  source = "../../"

  location                   = azurerm_resource_group.example.location
  name                       = "backup-vault-postgresql-flex"
  resource_group_name        = azurerm_resource_group.example.name
  datastore_type             = "VaultStore"
  redundancy                 = "LocallyRedundant"
  default_retention_duration = "P4M"
  identity_enabled           = true
  enable_telemetry           = true

  # Inputs for PostgreSQL Flexible backup policy and backup instance
  backup_policy_name                       = "${module.naming.postgresql_server.name_unique}-backup-policy"
  postgresql_flexible_backup_instance_name = "${module.naming.postgresql_server.name_unique}-postgresflex-instance"
  server_id                                = azurerm_postgresql_flexible_server.example.id

  role_assignments = {
    postgresql_Contributor = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Contributor"
      scope                      = azurerm_postgresql_flexible_server.example.id
    }
  }

  backup_repeating_time_intervals = ["R/2024-09-17T06:33:16+00:00/PT4H"]
  retention_rules = [
    {
      name     = "Daily"
      duration = "P7D"
      priority = 25
      criteria = [{ absolute_criteria = "FirstOfDay" }]
    }
  ]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9.3)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.110.0, < 5.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_postgresql_flexible_server.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) (resource)
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

### <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id)

Description: The tenant ID for the Azure Key Vault

Type: `string`

Default: `null`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_backup_vault"></a> [backup\_vault](#module\_backup\_vault)

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