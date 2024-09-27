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
  storage_account_type = "Standard_LRS"
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
