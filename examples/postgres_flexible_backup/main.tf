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

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# Random region selection
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# Generate a secure password for PostgreSQL
resource "random_password" "postgres_password" {
  length           = 16
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  special          = true
}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["postgres"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = "centralus"
  name     = module.naming.resource_group.name_unique
}

# Create a PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "example" {
  location               = azurerm_resource_group.example.location
  name                   = module.naming.postgresql_server.name_unique
  resource_group_name    = azurerm_resource_group.example.name
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres_password.result
  sku_name               = "GP_Standard_D4s_v3"
  storage_mb             = 32768
  version                = "12"
  zone                   = "2"

  # Define a custom maintenance window
  maintenance_window {
    day_of_week  = "4" # Thursday
    start_hour   = 2   # 2 AM, adjusted to off-peak time
    start_minute = 34
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
  postgresql_flexible_server_id            = azurerm_postgresql_flexible_server.example.id != "" ? azurerm_postgresql_flexible_server.example.id : null

  role_assignments = {
    postgresql_contributor = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Contributor"
      scope                      = azurerm_postgresql_flexible_server.example.id
      description                = "Allow backup vault identity to perform backup operations on PostgreSQL Flexible server"
    }
    resource_group_reader = {
      principal_id               = module.backup_vault.identity_principal_id
      role_definition_id_or_name = "Reader"
      scope                      = azurerm_resource_group.example.id
      description                = "Allow backup vault identity to read resource group information"
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
