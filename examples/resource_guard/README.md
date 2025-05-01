<!-- BEGIN_TF_DOCS -->
# Resource Guard Example

This example demonstrates how to deploy Azure Data Protection Backup Vault with a Resource Guard to protect against accidental or malicious operations on the vault.

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "backup_mua_operator" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = module.backup_vault.resource_guard_id
  role_definition_name = "Backup MUA Operator"
}


# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["resourceguard"]
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  location = "eastus2"
  name     = module.naming.resource_group.name_unique
  tags = {
    Environment = "Demo"
    Purpose     = "Resource Guard Example"
  }
}

# Create a Backup Vault with Resource Guard protection
module "backup_vault" {
  source = "../../"

  name                = module.naming.recovery_services_vault.name_unique
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Required parameters
  datastore_type = "VaultStore"
  redundancy     = "GeoRedundant"

  # Enable system-assigned managed identity
  identity_enabled = true

  # Resource Guard configuration
  resource_guard_enabled = true
  resource_guard_name    = "${module.naming.recovery_services_vault.name_unique}-guard"

  # Optional: exclude specific operations from protection
  vault_critical_operation_exclusion_list = [
    "Update" # Allow updates without Resource Guard protection
  ]

  # Tags
  tags = {
    Environment = "Demo"
    Service     = "Data Protection"
    CreatedBy   = "Terraform"
  }
}

# Output the backup vault ID
output "backup_vault_id" {
  description = "The ID of the backup vault"
  value       = module.backup_vault.backup_vault_id
}

# Output the Resource Guard ID
output "resource_guard_id" {
  description = "The ID of the Resource Guard"
  value       = module.backup_vault.resource_guard_id
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.7.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.backup_mua_operator](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_backup_vault_id"></a> [backup\_vault\_id](#output\_backup\_vault\_id)

Description: The ID of the backup vault

### <a name="output_resource_guard_id"></a> [resource\_guard\_id](#output\_resource\_guard\_id)

Description: The ID of the Resource Guard

## Modules

The following Modules are called:

### <a name="module_backup_vault"></a> [backup\_vault](#module\_backup\_vault)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->