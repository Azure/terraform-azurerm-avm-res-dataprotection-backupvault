<!-- BEGIN_TF_DOCS -->
# Disk Backup Example

This example demonstrates how to deploy the `azurerm_data_protection_backup_vault` module with a disk backup instance, backup policy, and managed disk for a comprehensive Azure managed disk backup solution.

```hcl
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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Random region selection
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
  prefix  = ["avm"]
  suffix  = ["demo"]
}

# Resource Group
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
  tags = {
    Environment = "Demo"
    Deployment  = "Terraform"
    Service     = "Data Protection"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "example" {
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.log_analytics_workspace.name_unique}-law"
  resource_group_name = azurerm_resource_group.example.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# Managed Disk
resource "azurerm_managed_disk" "example" {
  create_option        = "Empty"
  location             = azurerm_resource_group.example.location
  name                 = "${module.naming.managed_disk.name_unique}-disk"
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 64
  tags = {
    Environment = "Demo"
    Purpose     = "Disk Backup"
  }
}

# Snapshot Resource Group
resource "azurerm_resource_group" "snapshots" {
  location = azurerm_resource_group.example.location
  name     = "${module.naming.resource_group.name_unique}-snapshots"
  tags = {
    Environment = "Demo"
    Purpose     = "Disk Snapshots"
  }
}

# Backup Vault Module
module "backup_vault" {
  source = "../../"

  name                = "${module.naming.recovery_services_vault.name_unique}-vault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"

  default_retention_duration             = "P30D"
  vault_default_retention_duration       = "P90D"
  operational_default_retention_duration = "P30D"
  retention_duration_in_days             = 14

  immutability     = "Disabled"
  soft_delete      = "Off"
  identity_enabled = true

  lock = null

  diagnostic_settings = {
    diag_to_law = {
      name                  = "diag-law"
      log_categories        = []
      log_groups            = ["allLogs"]
      metric_categories     = ["Health"]
      workspace_resource_id = azurerm_log_analytics_workspace.example.id
    }
  }
  backup_policy_name              = "${module.naming.recovery_services_vault.name_unique}-disk-policy"
  backup_repeating_time_intervals = ["R/2025-01-01T00:00:00+00:00/P1D"]

  disk_backup_instance_name    = "${module.naming.recovery_services_vault.name_unique}-disk-instance"
  disk_id                      = azurerm_managed_disk.example.id
  snapshot_resource_group_name = azurerm_resource_group.snapshots.name

  role_assignments = {
    disk_backup_reader = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Disk Backup Reader"
      scope                      = azurerm_managed_disk.example.id
    }
    disk_snapshot_contributor = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Disk Snapshot Contributor"
      scope                      = azurerm_resource_group.snapshots.id
    }
  }

  retention_rules = [
    {
      name     = "Daily"
      priority = 25
      duration = "P7D"
      criteria = [{
        absolute_criteria = "FirstOfDay"
      }]
    },
    {
      name     = "Weekly"
      priority = 20
      duration = "P30D"
      criteria = [{
        absolute_criteria = "FirstOfWeek"
      }]
    }
  ]

  tags = {
    Environment = "Demo"
    Service     = "Data Protection"
    CreatedBy   = "Terraform"
  }

  enable_telemetry = true
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.7.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.9)

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_managed_disk.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.snapshots](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
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