terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0"
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

provider "azapi" {}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  prefix = ["avm"]
  suffix = ["demo"]
}

# Resource Group
resource "azurerm_resource_group" "example" {
  location = "centralus"
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

  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.recovery_services_vault.name_unique}-vault"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.example.name
  # Define backup instance that references policy
  backup_instances = {
    "disk-instance" = {
      type                         = "disk"
      name                         = "${module.naming.recovery_services_vault.name_unique}-disk-instance"
      backup_policy_key            = "disk-daily"
      disk_id                      = azurerm_managed_disk.example.id
      snapshot_resource_group_name = azurerm_resource_group.snapshots.name
    }
  }
  # Define backup policy
  backup_policies = {
    "disk-daily" = {
      type                            = "disk"
      name                            = "${module.naming.recovery_services_vault.name_unique}-disk-policy"
      backup_repeating_time_intervals = ["R/2025-01-01T00:00:00+00:00/P1D"]
      default_retention_duration      = "P30D"
      time_zone                       = "UTC"
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
    }
  }
  # Configure diagnostic settings
  diagnostic_settings = {
    diag_to_law = {
      name                  = "diag-law"
      log_categories        = []
      log_groups            = ["allLogs"]
      metric_categories     = ["Health"]
      workspace_resource_id = azurerm_log_analytics_workspace.example.id
    }
  }
  enable_telemetry = true
  immutability     = "Disabled"
  lock             = null
  # Configure managed identity
  managed_identities = {
    system_assigned = true
  }
  soft_delete = "Off"
  tags = {
    Environment = "Demo"
    Service     = "Data Protection"
    CreatedBy   = "Terraform"
  }
}

# Create role assignments outside the module to avoid circular dependencies
resource "azurerm_role_assignment" "disk_backup_reader" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_managed_disk.example.id
  role_definition_name = "Disk Backup Reader"
}

resource "azurerm_role_assignment" "disk_snapshot_contributor" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_resource_group.snapshots.id
  role_definition_name = "Disk Snapshot Contributor"
}
