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
  suffix  = ["disk"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Create a Managed Disk
resource "azurerm_managed_disk" "example" {
  create_option        = "Empty"
  location             = azurerm_resource_group.example.location
  name                 = "${module.naming.managed_disk.name_unique}-disk"
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 64
}

# Module Call for Backup Vault and Disk Backup
module "backup_vault" {
  source = "../../"

  location                               = azurerm_resource_group.example.location
  name                                   = "${module.naming.recovery_services_vault.name_unique}-vault"
  resource_group_name                    = azurerm_resource_group.example.name
  datastore_type                         = "VaultStore"
  redundancy                             = "LocallyRedundant"
  vault_default_retention_duration       = "P90D"
  operational_default_retention_duration = "P30D"
  default_retention_duration             = "P4M"
  identity_enabled                       = true
  enable_telemetry                       = true

  # Inputs for backup policy and backup instance
  backup_policy_name           = "${module.naming.recovery_services_vault.name_unique}-backup-policy"
  disk_backup_instance_name    = "${module.naming.recovery_services_vault.name_unique}-disk-instance"
  disk_id                      = azurerm_managed_disk.example.id
  snapshot_resource_group_name = azurerm_resource_group.example.name
  backup_policy_id             = module.backup_vault.backup_policy_id

  role_assignments = {
    # Assign Disk Snapshot Contributor role to the Snapshot Resource Group
    snapshot_contributor = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Disk Snapshot Contributor"
      scope                      = azurerm_resource_group.example.id # Snapshot Resource Group scope
    }

    # Assign Disk Backup Reader role to the Disk
    backup_reader = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Disk Backup Reader"
      scope                      = azurerm_managed_disk.example.id # Disk resource scope
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
        duration        = "P30D" # Specify a valid retention duration here
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
        duration        = "P30D" # Specify a valid retention duration here
      }]
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

- [azurerm_managed_disk.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

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