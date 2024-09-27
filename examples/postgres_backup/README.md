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

resource "random_integer" "region_index" {
  max = 5
  min = 0
}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["postgres"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = "Central US"
  name     = module.naming.resource_group.name_unique
}

# Create a PostgreSQL Server and Database
resource "azurerm_postgresql_server" "example" {
  location                         = azurerm_resource_group.example.location
  name                             = module.naming.postgresql_server.name_unique
  resource_group_name              = azurerm_resource_group.example.name
  sku_name                         = "GP_Gen5_4"
  ssl_enforcement_enabled          = true
  version                          = "11"
  administrator_login              = "psqladmin"
  administrator_login_password     = "H@Sh1CoR3!"
  auto_grow_enabled                = true
  backup_retention_days            = 7
  geo_redundant_backup_enabled     = true
  public_network_access_enabled    = false
  ssl_minimal_tls_version_enforced = "TLS1_2"
  storage_mb                       = 640000
}

resource "azurerm_postgresql_database" "example" {
  charset             = "UTF8"
  collation           = "English_United States.1252"
  name                = module.naming.postgresql_database.name_unique
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_server.example.name
}

# Module Call for PostgreSQL Backup Vault and Backup Policy
module "backup_vault" {
  source = "../../"

  location                   = azurerm_resource_group.example.location
  name                       = "backup-vault-postgresql"
  resource_group_name        = azurerm_resource_group.example.name
  datastore_type             = "VaultStore"
  redundancy                 = "LocallyRedundant"
  default_retention_duration = "P4M"
  identity_enabled           = true
  enable_telemetry           = true

  # Inputs for PostgreSQL backup policy and backup instance
  backup_policy_name              = "${module.naming.postgresql_server.name_unique}-backup-policy"
  postgresql_backup_instance_name = "${module.naming.postgresql_database.name_unique}-postgressql-instance"
  postgresql_database_id          = azurerm_postgresql_database.example.id

  role_assignments = {
    postgresql_Contributor = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Contributor"
      scope                      = azurerm_postgresql_server.example.id
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

- [azurerm_postgresql_database.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_database) (resource)
- [azurerm_postgresql_server.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_server) (resource)
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

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->