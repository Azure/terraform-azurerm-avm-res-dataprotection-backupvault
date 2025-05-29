terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"

  suffix = ["aks"]
}

# Resource groups
resource "azurerm_resource_group" "example" {
  location = "eastus2"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_resource_group" "snap" {
  location = azurerm_resource_group.example.location
  name     = "${module.naming.resource_group.name_unique}-snap"
}

# AKS Cluster with System Identity
resource "azurerm_kubernetes_cluster" "example" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "aks${substr(module.naming.kubernetes_cluster.name_unique, -6, -1)}"

  default_node_pool {
    name                        = "default"
    vm_size                     = "Standard_D4s_v3"
    auto_scaling_enabled        = true
    max_count                   = 9
    min_count                   = 3
    orchestrator_version        = null
    os_disk_type                = "Managed"
    temporary_name_for_rotation = "tempnodepool"
    type                        = "VirtualMachineScaleSets"
    zones                       = ["1", "3"]

    upgrade_settings {
      max_surge                     = "33%"
      drain_timeout_in_minutes      = 15
      node_soak_duration_in_minutes = 15
    }
  }
  identity {
    type = "SystemAssigned"
  }
}


# Storage account required for the AKS extension
resource "azurerm_storage_account" "example" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.example.location
  name                     = lower(replace("stgaks${substr(module.naming.resource_group.name_unique, -12, -1)}", "-", ""))
  resource_group_name      = azurerm_resource_group.example.name
}

resource "azurerm_storage_container" "example" {
  name                  = "backup"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.example.id
}

# Install the Kubernetes Data Protection extension
resource "azurerm_kubernetes_cluster_extension" "backup_extension" {
  cluster_id     = azurerm_kubernetes_cluster.example.id
  extension_type = "Microsoft.DataProtection.Kubernetes"
  name           = "backup-extension"
  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                = azurerm_storage_container.example.name
    "configuration.backupStorageLocation.config.resourceGroup"  = azurerm_resource_group.example.name
    "configuration.backupStorageLocation.config.storageAccount" = azurerm_storage_account.example.name
    "configuration.backupStorageLocation.config.subscriptionId" = data.azurerm_client_config.current.subscription_id
    "credentials.tenantId"                                      = data.azurerm_client_config.current.tenant_id
  }
  release_namespace = "dataprotection-microsoft"
  release_train     = "stable"
}

# Add wait after extension creation
resource "time_sleep" "wait_for_extension" {
  create_duration = "5m" # Allow 5 minutes for extension to initialize

  depends_on = [azurerm_kubernetes_cluster_extension.backup_extension]
}

# Grant the extension access to the storage account
resource "azurerm_role_assignment" "extension_storage_access" {
  principal_id         = azurerm_kubernetes_cluster_extension.backup_extension.aks_assigned_identity[0].principal_id
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Account Contributor"

  depends_on = [time_sleep.wait_for_extension]
}

# Backup vault using the module
module "backup_vault" {
  source = "../../"

  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.recovery_services_vault.name_unique}-vault"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.example.name
  # Specify backup datasource parameters
  backup_datasource_parameters = {
    excluded_namespaces              = ["kube-system", "kube-public"]
    included_namespaces              = ["default", "app-namespace"]
    cluster_scoped_resources_enabled = true
    volume_snapshot_enabled          = true
  }
  backup_repeating_time_intervals = ["R/2024-12-01T02:30:00+00:00/P1W"]
  # AKS default retention configuration
  default_retention_life_cycle = {
    data_store_type = "OperationalStore"
    duration        = "P14D"
  }
  enable_telemetry = true
  identity_enabled = true
  # AKS backup instance configuration
  kubernetes_backup_instance_name = "${module.naming.kubernetes_cluster.name_unique}-backup-instance"
  # AKS backup policy configuration
  kubernetes_backup_policy_name = "${module.naming.kubernetes_cluster.name_unique}-policy"
  kubernetes_cluster_id         = azurerm_kubernetes_cluster.example.id
  # Additional retention rules
  kubernetes_retention_rules = [
    {
      name              = "Weekly"
      priority          = 25
      absolute_criteria = "FirstOfWeek"
      data_store_type   = "OperationalStore"
      duration          = "P84D"
    },
    {
      name              = "Monthly"
      priority          = 20
      absolute_criteria = "FirstOfMonth"
      data_store_type   = "OperationalStore"
      duration          = "P365D"
    }
  ]
  snapshot_resource_group_name = azurerm_resource_group.snap.name
  time_zone                    = "UTC"

  depends_on = [time_sleep.wait_for_extension]
}

# Create trusted access role binding between AKS and backup vault
resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "backup_access" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  name                  = "backup-operator-binding"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = module.backup_vault.backup_vault_id

  depends_on = [module.backup_vault]
}

# Required role assignments for AKS backup to function properly
# FIXED: Removed depends_on from inside the for_each map
resource "azurerm_role_assignment" "required_roles" {
  for_each = {
    vault_cluster_reader = {
      role         = "Reader"
      scope        = azurerm_kubernetes_cluster.example.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_snap_rg_reader = {
      role         = "Reader"
      scope        = azurerm_resource_group.snap.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_snapshot_contributor = {
      role         = "Disk Snapshot Contributor"
      scope        = azurerm_resource_group.snap.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_disk_operator = {
      role         = "Data Operator for Managed Disks"
      scope        = azurerm_resource_group.snap.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_storage_contributor = {
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_account.example.id
      principal_id = module.backup_vault.identity_principal_id
    }
    cluster_snap_contributor = {
      role         = "Contributor"
      scope        = azurerm_resource_group.snap.id
      principal_id = azurerm_kubernetes_cluster.example.identity[0].principal_id
    }
  }

  principal_id         = each.value.principal_id
  scope                = each.value.scope
  role_definition_name = each.value.role

  # FIXED: Moved depends_on to the resource level instead of inside the for_each map
  depends_on = [time_sleep.wait_for_extension, module.backup_vault]
}

# Wait for role assignments to propagate before creating backup resources
resource "time_sleep" "wait_for_rbac" {
  # Azure RBAC can take time to propagate
  create_duration = "2m"

  depends_on = [
    azurerm_role_assignment.required_roles,
    azurerm_kubernetes_cluster_trusted_access_role_binding.backup_access,
    azurerm_role_assignment.extension_storage_access
  ]
}
