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
