terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
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

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  prefix = ["avm"]
  suffix = ["flexible"]
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

# Snapshot Resource Group
resource "azurerm_resource_group" "snapshots" {
  location = azurerm_resource_group.example.location
  name     = "${module.naming.resource_group.name_unique}-snapshots"
  tags = {
    Environment = "Demo"
    Purpose     = "Disk Snapshots"
  }
}

# First Managed Disk (Primary/Production)
resource "azurerm_managed_disk" "example" {
  create_option        = "Empty"
  location             = azurerm_resource_group.example.location
  name                 = "${module.naming.managed_disk.name_unique}-primary"
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 64
  tags = {
    Environment = "Demo"
    Purpose     = "Production Disk"
  }
}

# Second Managed Disk (Secondary/Development)
resource "azurerm_managed_disk" "database" {
  create_option        = "Empty"
  location             = azurerm_resource_group.example.location
  name                 = "${module.naming.managed_disk.name_unique}-secondary"
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 32
  tags = {
    Environment = "Demo"
    Purpose     = "Development Disk"
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
  # Define multiple backup instances that reference policies
  backup_instances = {
    # Production disk instance
    "production-disk" = {
      type                         = "disk"
      name                         = "${module.naming.recovery_services_vault.name_unique}-prod-instance"
      backup_policy_key            = "production-daily"
      disk_id                      = azurerm_managed_disk.example.id
      snapshot_resource_group_name = azurerm_resource_group.snapshots.name
    },

    # Development disk instance
    "development-disk" = {
      type                         = "disk"
      name                         = "${module.naming.recovery_services_vault.name_unique}-dev-instance"
      backup_policy_key            = "development-weekly"
      disk_id                      = azurerm_managed_disk.database.id
      snapshot_resource_group_name = azurerm_resource_group.snapshots.name
    }
  }
  # Define multiple backup policies independently
  backup_policies = {
    # Production disk policy - daily backups with long retention
    "production-daily" = {
      type                                   = "disk"
      name                                   = "${module.naming.recovery_services_vault.name_unique}-prod-policy"
      backup_repeating_time_intervals        = ["R/2025-01-01T00:00:00+00:00/P1D"]
      default_retention_duration             = "P7D"
      operational_default_retention_duration = "P30D"
      time_zone                              = "UTC"
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
    },

    # Development disk policy - weekly backups
    "development-weekly" = {
      type                                   = "disk"
      name                                   = "${module.naming.recovery_services_vault.name_unique}-dev-policy"
      backup_repeating_time_intervals        = ["R/2025-01-01T00:00:00+00:00/P1W"]
      default_retention_duration             = "P30D"
      operational_default_retention_duration = "P14D"
      time_zone                              = "UTC"
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
resource "azurerm_role_assignment" "disk_backup_reader_primary" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_managed_disk.example.id
  role_definition_name = "Disk Backup Reader"
}

resource "azurerm_role_assignment" "disk_backup_reader_secondary" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_managed_disk.database.id
  role_definition_name = "Disk Backup Reader"
}

resource "azurerm_role_assignment" "disk_snapshot_contributor" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_resource_group.snapshots.id
  role_definition_name = "Disk Snapshot Contributor"
}
