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
